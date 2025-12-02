# 💰 Sistema de Faturamento - PhysioCore SaaS

## Visão Geral

Sistema completo de faturamento com bloqueio automático de empresas inadimplentes. Apenas usuários com role `machine` podem gerenciar pagamentos e desbloquear empresas.

---

## 📋 Campos de Faturamento (Company)

### Campos Adicionados

```ruby
billing_day: Integer         # Dia do mês para fechamento da fatura (1-31)
billing_due_date: Date       # Próxima data de vencimento
payment_status: String       # Status do pagamento: 'paid', 'pending', 'overdue'
last_payment_date: Date      # Data do último pagamento realizado
```

### Status de Pagamento

- **paid**: Pagamento em dia, empresa ativa
- **pending**: Aguardando pagamento (não bloqueia acesso ainda)
- **overdue**: Pagamento atrasado, empresa suspensa automaticamente

---

## 🔒 Sistema de Bloqueio Automático

### Middleware de Verificação

O `AuthMiddleware` verifica automaticamente se a empresa está com pagamento em dia:

```ruby
# Se payment_status == 'overdue', retorna 403:
{
  "error": "Company payment is overdue. Access suspended.",
  "payment_status": "overdue",
  "billing_due_date": "2025-01-15"
}
```

**Exceção**: Usuários com role `machine` **não são bloqueados** e podem acessar todas as empresas.

---

## 🤖 Job de Verificação Automática

### CheckOverduePayments

Arquivo: `app/jobs/check_overdue_payments.rb`

**Função**: Verifica diariamente empresas com `billing_due_date` vencida e suspende automaticamente.

```ruby
# Execução manual
require_relative './app/jobs/check_overdue_payments'
CheckOverduePayments.run
```

### Configuração do Cron (Linux)

```bash
# Editar crontab
crontab -e

# Adicionar linha para executar todo dia às 00:00
0 0 * * * cd /home/jsilva/fisio/fisio_back && bundle exec ruby -e "require './config/environment'; require './app/jobs/check_overdue_payments'; CheckOverduePayments.run" >> /var/log/physiocore_billing.log 2>&1
```

### Alternativa com Rake Task

Criar `Rakefile`:

```ruby
require_relative 'config/environment'
require_relative 'app/jobs/check_overdue_payments'

task :check_overdue_payments do
  CheckOverduePayments.run
end
```

Cron:
```bash
0 0 * * * cd /home/jsilva/fisio/fisio_back && bundle exec rake check_overdue_payments >> /var/log/physiocore_billing.log 2>&1
```

---

## 🔧 API Endpoints (Machine Only)

### Base URL
```
/api/billing
```

**Autenticação**: Apenas role `machine`

---

### 1. Listar Empresas Inadimplentes

**GET** `curl -X POST http://localhost:9292/api/companies \
  -H "Authorization: Bearer $MACHINE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Clínica Vida Saudável",
    "email": "contato@vidasaudavel.com",
    "phone": "(11) 98888-7777",
    "plan": "premium",
    "billing_day": 10
  }'

Lista todas as empresas com `payment_status == 'overdue'`.

**Response:**
```json
{
  "total": 2,
  "companies": [
    {
      "id": "692f1ffac90196fdf2a4fe2f",
      "name": "DJM Fisioterapia",
      "slug": "djm-fisioterapia",
      "email": "contato@djm.com",
      "plan": "basic",
      "billing_day": 15,
      "billing_due_date": "2025-01-15",
      "payment_status": "overdue",
      "last_payment_date": "2024-12-15",
      "days_overdue": 18,
      "status": "suspended"
    }
  ]
}
```

---

### 2. Listar Vencimentos Próximos

**GET** `/api/billing/pending`

Lista empresas com vencimento nos próximos 7 dias.

**Response:**
```json
{
  "total": 3,
  "companies": [
    {
      "id": "692f1ffac90196fdf2a4fe2f",
      "name": "DJM Fisioterapia",
      "slug": "djm-fisioterapia",
      "email": "contato@djm.com",
      "plan": "premium",
      "billing_day": 5,
      "billing_due_date": "2025-02-05",
      "days_until_due": 3,
      "last_payment_date": "2025-01-05"
    }
  ]
}
```

---

### 3. Marcar Pagamento como Realizado

**POST** `/api/billing/:company_id/mark-paid`

Marca pagamento como realizado, desbloqueia empresa e calcula próximo vencimento.

**Ações Automáticas:**
- `payment_status` → `'paid'`
- `last_payment_date` → Data atual
- `status` → `'active'` (se estava suspensa)
- `billing_due_date` → Próximo vencimento calculado

**Response:**
```json
{
  "message": "Payment marked as paid successfully",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia",
    "payment_status": "paid",
    "last_payment_date": "2025-02-02",
    "billing_due_date": "2025-03-15",
    "status": "active"
  }
}
```

---

### 4. Atualizar Dia de Fechamento

**POST** `/api/billing/:company_id/update-billing-day`

Atualiza o `billing_day` e recalcula `billing_due_date`.

**Request:**
```json
{
  "billing_day": 20
}
```

**Response:**
```json
{
  "message": "Billing day updated successfully",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia",
    "billing_day": 20,
    "billing_due_date": "2025-02-20"
  }
}
```

---

### 5. Executar Verificação Manual

**POST** `/api/billing/run-check`

Executa manualmente o job `CheckOverduePayments`.

**Response:**
```json
{
  "message": "Payment check completed",
  "companies_suspended": 2,
  "timestamp": "2025-02-02T10:30:00-03:00"
}
```

---

### 6. Estatísticas de Faturamento

**GET** `/api/billing/stats`

Retorna estatísticas gerais do faturamento.

**Response:**
```json
{
  "total_companies": 15,
  "payment_status": {
    "paid": 10,
    "pending": 3,
    "overdue": 2
  },
  "due_soon_7_days": 4,
  "suspended_by_payment": 2
}
```

---

## 📅 Lógica de Cálculo de Vencimento

### Método `calculate_next_due_date`

```ruby
# Exemplo: billing_day = 15, hoje = 02/02/2025
# Resultado: 15/02/2025

# Exemplo: billing_day = 15, hoje = 20/02/2025
# Resultado: 15/03/2025 (próximo mês)

# Exemplo: billing_day = 31, mês atual = fevereiro
# Resultado: 28/02/2025 (último dia do mês)
```

---

## 🛠️ Métodos do Model Company

```ruby
# Verifica se pagamento está em dia
company.payment_ok?  # => true/false

# Verifica se está atrasado
company.payment_overdue?  # => true/false

# Calcula próximo vencimento
company.calculate_next_due_date  # => Date

# Atualiza data de vencimento
company.update_due_date!

# Marca como pago (desbloqueia)
company.mark_as_paid!

# Marca como atrasado (bloqueia)
company.mark_as_overdue!
```

---

## 🔐 Controle de Acesso

### Usuários Normais (admin/user)
- ❌ **Não podem** acessar rotas `/api/billing/*`
- ❌ **Não podem** alterar `payment_status` ou `billing_day`
- ❌ **Bloqueados automaticamente** se `payment_status == 'overdue'`

### Usuário Machine
- ✅ **Pode** acessar todas rotas `/api/billing/*`
- ✅ **Pode** marcar pagamentos como realizados
- ✅ **Pode** alterar dia de fechamento
- ✅ **Nunca é bloqueado** por pagamento atrasado

---

## 📋 Exemplo de Fluxo Completo

### 1. Criar Empresa com Faturamento

```bash
curl -X POST http://localhost:9292/api/companies \
  -H "Authorization: Bearer $MACHINE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Clínica Exemplo",
    "email": "clinica@exemplo.com",
    "plan": "premium",
    "billing_day": 10
  }'
```

### 2. Sistema Calcula Primeiro Vencimento

```json
{
  "billing_day": 10,
  "billing_due_date": "2025-02-10",
  "payment_status": "paid",
  "status": "active"
}
```

### 3. Cron Verifica Vencimento (todo dia 00:00)

```
[2025-02-11 00:00:01] Iniciando verificação de pagamentos atrasados...
  - Empresa Clínica Exemplo (clinica-exemplo) com pagamento atrasado desde 2025-02-10
[2025-02-11 00:00:02] Verificação concluída. 1 empresa(s) suspensa(s).
```

### 4. Empresa Fica Suspensa

```json
{
  "payment_status": "overdue",
  "status": "suspended"
}
```

### 5. Machine Recebe Pagamento e Libera

```bash
curl -X POST http://localhost:9292/api/billing/692f1ffac90196fdf2a4fe2f/mark-paid \
  -H "Authorization: Bearer $MACHINE_TOKEN"
```

### 6. Empresa Reativada

```json
{
  "payment_status": "paid",
  "last_payment_date": "2025-02-11",
  "billing_due_date": "2025-03-10",
  "status": "active"
}
```

---

## ⚠️ Importante

1. **Apenas machine pode desbloquear empresas**
2. **Bloqueio é automático via cron + middleware**
3. **Empresas suspensas não conseguem fazer login** (exceto machine vendo dados delas)
4. **billing_day aceita 1-31**, ajusta automaticamente para último dia do mês se necessário
5. **Configurar cron em produção é essencial** para funcionamento automático

---

## 🚀 Próximos Passos

- [ ] Integrar com gateway de pagamento (Stripe, Mercado Pago, etc)
- [ ] Enviar emails de notificação de vencimento (7, 3 e 1 dia antes)
- [ ] Enviar email ao suspender empresa
- [ ] Dashboard de faturamento no frontend
- [ ] Relatórios de receita mensal/anual
- [ ] Histórico de pagamentos por empresa
