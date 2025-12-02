# 💰 Exemplos de CURL - Sistema de Faturamento

## 🔐 Autenticação (Machine)

Primeiro, faça login com o usuário machine para obter o token:

```bash
# 1. Login como Machine
curl -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "machine@sistema.com",
    "password": "machine123"
  }'
```

**Response:**
```json
{
  "status": "success",
  "message": "Login realizado com sucesso",
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "_id": "692f1e0cc9c0c64069141b2e",
    "email": "machine@sistema.com",
    "role": "machine"
  }
}
```

**Copie o token e use nas próximas requisições!**

---

## 📊 Estatísticas de Faturamento

### GET /api/billing/stats

Retorna estatísticas gerais do sistema de faturamento.

```bash
curl -X GET http://localhost:9292/api/billing/stats \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Response Example:**
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

## 🚨 Listar Empresas Inadimplentes

### GET /api/billing/overdue

Lista todas as empresas com pagamento atrasado (`payment_status == 'overdue'`).

```bash
curl -X GET http://localhost:9292/api/billing/overdue \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Response Example:**
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

## ⏰ Listar Vencimentos Próximos (7 dias)

### GET /api/billing/pending

Lista empresas com vencimento nos próximos 7 dias.

```bash
curl -X GET http://localhost:9292/api/billing/pending \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Response Example:**
```json
{
  "total": 3,
  "companies": [
    {
      "id": "692f1ffac90196fdf2a4fe2f",
      "name": "Clínica Saúde",
      "slug": "clinica-saude",
      "email": "contato@clinicasaude.com",
      "plan": "premium",
      "billing_day": 5,
      "billing_due_date": "2025-12-09",
      "days_until_due": 7,
      "last_payment_date": "2025-11-05"
    }
  ]
}
```

---

## ✅ Marcar Pagamento como Realizado

### POST /api/billing/:company_id/mark-paid

Marca pagamento como realizado, desbloqueia a empresa e calcula o próximo vencimento.

**Ações Automáticas:**
- `payment_status` → `'paid'`
- `last_payment_date` → Data atual
- `status` → `'active'` (se estava suspensa)
- `billing_due_date` → Próximo vencimento calculado

```bash
# Substitua 692f1ffac90196fdf2a4fe2f pelo ID da empresa
curl -X POST http://localhost:9292/api/billing/692f1ffac90196fdf2a4fe2f/mark-paid \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Response Example:**
```json
{
  "message": "Payment marked as paid successfully",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia",
    "payment_status": "paid",
    "last_payment_date": "2025-12-02",
    "billing_due_date": "2026-01-02",
    "status": "active"
  }
}
```

---

## 📅 Atualizar Dia de Fechamento

### POST /api/billing/:company_id/update-billing-day

Atualiza o dia do mês para fechamento da fatura (1-31).

```bash
# Substitua 692f1ffac90196fdf2a4fe2f pelo ID da empresa
curl -X POST http://localhost:9292/api/billing/692f1ffac90196fdf2a4fe2f/update-billing-day \
  -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "billing_day": 20
  }'
```

**Response Example:**
```json
{
  "message": "Billing day updated successfully",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia",
    "billing_day": 20,
    "billing_due_date": "2025-12-20"
  }
}
```

---

## 🔄 Executar Verificação Manual de Pagamentos

### POST /api/billing/run-check

Executa manualmente o job de verificação de pagamentos atrasados (mesmo job que o cron executa).

```bash
curl -X POST http://localhost:9292/api/billing/run-check \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

**Response Example:**
```json
{
  "message": "Payment check completed",
  "companies_suspended": 2,
  "timestamp": "2025-12-02T15:10:00-03:00"
}
```

**Log do Job:**
```
[2025-12-02 15:10:00 -0300] Iniciando verificação de pagamentos atrasados...
  - Empresa DJM Fisioterapia (djm-fisioterapia) com pagamento atrasado desde 2025-11-15
  - Empresa Clínica ABC (clinica-abc) com pagamento atrasado desde 2025-11-20
[2025-12-02 15:10:01 -0300] Verificação concluída. 2 empresa(s) suspensa(s).
```

---

## 🧪 Testando Bloqueio de Acesso

### Simular empresa com pagamento atrasado

1. **Atualizar billing_due_date para data passada** (via console/script)
2. **Executar verificação manual:**

```bash
curl -X POST http://localhost:9292/api/billing/run-check \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

3. **Tentar fazer login como usuário da empresa bloqueada:**

```bash
curl -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@djm.com",
    "password": "senha123"
  }'
```

**Response (se bloqueado):**
```json
{
  "error": "Pagamento em atraso. Acesso suspenso.",
  "payment_status": "overdue",
  "billing_due_date": "2025-11-15"
}
```

---

## 🔒 Teste de Validação de Role

### Tentar acessar rota de billing com usuário comum (não machine)

```bash
# 1. Login como usuário comum (admin da empresa)
TOKEN_ADMIN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@djm.com", "password": "senha123"}' | jq -r .token)

# 2. Tentar acessar rota de billing
curl -X GET http://localhost:9292/api/billing/stats \
  -H "Authorization: Bearer $TOKEN_ADMIN"
```

**Response Esperado (403 Forbidden):**
```json
{
  "error": "Access denied. Machine role required."
}
```

✅ **Isso confirma que apenas machine pode acessar as rotas de billing!**

---

## 🎯 Script Completo de Teste

```bash
#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:9292"

echo -e "${YELLOW}=== TESTANDO SISTEMA DE FATURAMENTO ===${NC}\n"

# 1. Login Machine
echo -e "${YELLOW}1. Login como Machine...${NC}"
RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "machine@sistema.com", "password": "machine123"}')

TOKEN=$(echo $RESPONSE | jq -r .token)

if [ "$TOKEN" != "null" ]; then
  echo -e "${GREEN}✓ Login realizado com sucesso${NC}"
  echo "Token: ${TOKEN:0:30}..."
else
  echo -e "${RED}✗ Erro no login${NC}"
  exit 1
fi

echo ""

# 2. Estatísticas
echo -e "${YELLOW}2. Buscando estatísticas...${NC}"
curl -s -X GET $BASE_URL/api/billing/stats \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 3. Empresas inadimplentes
echo -e "${YELLOW}3. Listando empresas inadimplentes...${NC}"
curl -s -X GET $BASE_URL/api/billing/overdue \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 4. Vencimentos próximos
echo -e "${YELLOW}4. Vencimentos próximos (7 dias)...${NC}"
curl -s -X GET $BASE_URL/api/billing/pending \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

# 5. Executar verificação manual
echo -e "${YELLOW}5. Executando verificação manual...${NC}"
curl -s -X POST $BASE_URL/api/billing/run-check \
  -H "Authorization: Bearer $TOKEN" | jq .
echo ""

echo -e "${GREEN}=== TESTES CONCLUÍDOS ===${NC}"
```

**Salve como `test_billing.sh` e execute:**
```bash
chmod +x test_billing.sh
./test_billing.sh
```

---

## 📝 Variáveis de Ambiente para Testes

Crie um arquivo `.env.test`:

```bash
# Machine Token (obtenha via login)
MACHINE_TOKEN="eyJhbGciOiJIUzI1NiJ9..."

# IDs de teste
COMPANY_ID="692f1ffac90196fdf2a4fe2f"

# Base URL
BASE_URL="http://localhost:9292"
```

Use em scripts:
```bash
source .env.test

curl -X GET $BASE_URL/api/billing/stats \
  -H "Authorization: Bearer $MACHINE_TOKEN"
```

---

## ✅ Checklist de Validações

- [x] **Token JWT válido** - Apenas machine pode acessar
- [x] **Role machine obrigatório** - Retorna 403 para outros roles
- [x] **Empresas inadimplentes** - Lista corretamente com days_overdue
- [x] **Vencimentos próximos** - Filtra próximos 7 dias
- [x] **Mark as paid** - Desbloqueia e calcula próximo vencimento
- [x] **Update billing day** - Recalcula billing_due_date
- [x] **Run check** - Executa job e suspende empresas
- [x] **Stats** - Retorna contadores corretos
- [x] **Bloqueio automático** - Middleware bloqueia login de empresas overdue

---

## 🚀 Produção

Para produção, substitua `localhost:9292` pela URL do seu servidor:

```bash
BASE_URL="https://api.physiocore.com"

curl -X GET $BASE_URL/api/billing/stats \
  -H "Authorization: Bearer $MACHINE_TOKEN"
```
