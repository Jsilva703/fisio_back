# 🏢 API de Empresas - PhysioCore

## Base URL
```
/api/companies
```

**Autenticação**: Apenas role `machine`

---

## Endpoints Disponíveis

### 1. Listar Todas as Empresas
**GET** `/api/companies`

Lista todas as empresas cadastradas no sistema.

**Response:**
```json
{
  "status": "success",
  "total": 2,
  "companies": [
    {
      "id": "692f1ffac90196fdf2a4fe2f",
      "name": "DJM Fisioterapia",
      "slug": "djm-fisioterapia",
      "email": "contato@djm.com",
      "phone": "(11) 99999-9999",
      "cnpj": "12.345.678/0001-99",
      "plan": "basic",
      "status": "active",
      "max_users": 5,
      "users_count": 2,
      "appointments_count": 15,
      "schedulings_count": 3,
      "created_at": "2025-12-01T10:00:00-03:00",
      "updated_at": "2025-12-02T15:30:00-03:00"
    }
  ]
}
```

---

### 2. Buscar Empresa por ID
**GET** `/api/companies/:id`

Retorna detalhes completos de uma empresa específica.

**Response:**
```json
{
  "status": "success",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia",
    "slug": "djm-fisioterapia",
    "email": "contato@djm.com",
    "phone": "(11) 99999-9999",
    "cnpj": "12.345.678/0001-99",
    "address": "Rua Exemplo, 123",
    "plan": "basic",
    "status": "active",
    "max_users": 5,
    "settings": {
      "working_hours": "08:00-18:00"
    },
    "users_count": 2,
    "appointments_count": 15,
    "schedulings_count": 3,
    "created_at": "2025-12-01T10:00:00-03:00",
    "updated_at": "2025-12-02T15:30:00-03:00"
  }
}
```

---

### 3. Criar Empresa
**POST** `/api/companies`

Cria uma nova empresa no sistema.

**Request Body:**
```json
{
  "name": "Clínica Exemplo",
  "email": "contato@clinica.com",
  "phone": "(11) 98888-7777",
  "cnpj": "12.345.678/0001-99",
  "address": "Rua Exemplo, 123",
  "plan": "professional",
  "max_users": 15,
  "billing_day": 10,
  "settings": {
    "working_hours": "08:00-18:00",
    "timezone": "America/Sao_Paulo"
  }
}
```

**Campos Obrigatórios:**
- `name` (String)
- `email` (String)

**Campos Opcionais:**
- `phone` (String)
- `cnpj` (String)
- `address` (String)
- `plan` (String): `basic` | `professional` | `premium` | `enterprise` (padrão: `basic`)
- `max_users` (Integer, padrão: 5)
- `billing_day` (Integer 1-31): Dia do mês para fechamento
- `settings` (Hash): Configurações customizadas

**Response 201:**
```json
{
  "status": "success",
  "message": "Empresa criada com sucesso",
  "company": {
    "id": "692f2cf9668713e58d3eddb1",
    "name": "Clínica Exemplo",
    "slug": "clinica-exemplo",
    "email": "contato@clinica.com",
    "plan": "professional",
    "status": "active",
    "billing_day": 10,
    "billing_due_date": "2026-01-10",
    "payment_status": "paid"
  }
}
```

---

### 4. Atualizar Empresa ⭐ NOVO
**PUT** `/api/companies/:id`

Atualiza informações de uma empresa existente.

**Request Body (todos campos opcionais):**
```json
{
  "name": "Clínica Exemplo Atualizada",
  "email": "novo@email.com",
  "phone": "(11) 99999-8888",
  "cnpj": "98.765.432/0001-11",
  "address": "Rua Nova, 456",
  "plan": "premium",
  "status": "active",
  "max_users": 20,
  "settings": {
    "working_hours": "07:00-19:00",
    "auto_confirm": true
  }
}
```

**Campos Permitidos:**
- `name` (String)
- `email` (String)
- `phone` (String)
- `cnpj` (String)
- `address` (String)
- `plan` (String): `basic` | `professional` | `premium` | `enterprise`
- `status` (String): `active` | `inactive` | `suspended`
- `max_users` (Integer, mínimo: 1)
- `settings` (Hash)

**Validações:**
- `plan` deve ser um dos valores permitidos
- `status` deve ser um dos valores permitidos
- `max_users` deve ser maior que 0

**Response 200:**
```json
{
  "status": "success",
  "message": "Empresa atualizada com sucesso",
  "company": {
    "id": "692f2cf9668713e58d3eddb1",
    "name": "Clínica Exemplo Atualizada",
    "slug": "clinica-exemplo",
    "email": "novo@email.com",
    "phone": "(11) 99999-8888",
    "cnpj": "98.765.432/0001-11",
    "address": "Rua Nova, 456",
    "plan": "premium",
    "status": "active",
    "max_users": 20,
    "billing_day": 10,
    "billing_due_date": "2026-01-10",
    "payment_status": "paid",
    "settings": {
      "working_hours": "07:00-19:00",
      "auto_confirm": true
    },
    "updated_at": "2025-12-02T16:00:00-03:00"
  }
}
```

**Response 400 (erro de validação):**
```json
{
  "error": "Plano inválido. Opções: basic, professional, premium, enterprise"
}
```

**Response 404:**
```json
{
  "error": "Empresa não encontrada"
}
```

---

### 5. Deletar Empresa
**DELETE** `/api/companies/:id`

Remove uma empresa do sistema. Só permite deletar se não houver dados associados.

**Response 200:**
```json
{
  "status": "success",
  "message": "Empresa deletada com sucesso"
}
```

**Response 409 (conflito - empresa com dados):**
```json
{
  "error": "Não é possível deletar empresa com dados associados",
  "users_count": 5,
  "appointments_count": 120,
  "schedulings_count": 10
}
```

---

### 6. Estatísticas da Empresa
**GET** `/api/companies/:id/stats`

Retorna estatísticas detalhadas de uma empresa.

**Response:**
```json
{
  "status": "success",
  "company_id": "692f1ffac90196fdf2a4fe2f",
  "company_name": "DJM Fisioterapia",
  "stats": {
    "users": {
      "total": 5,
      "max_allowed": 5,
      "by_role": {
        "admin": 1,
        "user": 4
      }
    },
    "appointments": {
      "total": 120,
      "by_status": {
        "scheduled": 30,
        "completed": 80,
        "cancelled": 10
      },
      "by_payment": {
        "paid": 90,
        "pending": 30
      },
      "total_revenue": 12500.50
    },
    "schedulings": {
      "total": 10
    }
  }
}
```

---

## 📋 Exemplos de Uso

### Autenticação
Primeiro faça login como machine:

```bash
# Login machine
TOKEN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "machine@sistema.com",
    "password": "sua_senha_machine"
  }' | jq -r '.token')

echo $TOKEN
```

### Criar Empresa
```bash
curl -X POST http://localhost:9292/api/companies \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Clínica Nova",
    "email": "contato@clinicanva.com",
    "phone": "(11) 99999-9999",
    "plan": "professional",
    "billing_day": 15
  }'
```

### Atualizar Empresa
```bash
curl -X PUT http://localhost:9292/api/companies/692f1ffac90196fdf2a4fe2f \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "premium",
    "max_users": 20,
    "settings": {
      "working_hours": "07:00-20:00",
      "auto_confirm": true
    }
  }'
```

### Atualizar Apenas Nome
```bash
curl -X PUT http://localhost:9292/api/companies/692f1ffac90196fdf2a4fe2f \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Novo Nome da Clínica"
  }'
```

### Atualizar Plano
```bash
curl -X PUT http://localhost:9292/api/companies/692f1ffac90196fdf2a4fe2f \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "enterprise"
  }'
```

### Suspender Empresa
```bash
curl -X PUT http://localhost:9292/api/companies/692f1ffac90196fdf2a4fe2f \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "suspended"
  }'
```

### Listar Todas
```bash
curl -X GET http://localhost:9292/api/companies \
  -H "Authorization: Bearer $TOKEN"
```

### Buscar por ID
```bash
curl -X GET http://localhost:9292/api/companies/692f1ffac90196fdf2a4fe2f \
  -H "Authorization: Bearer $TOKEN"
```

### Ver Estatísticas
```bash
curl -X GET http://localhost:9292/api/companies/692f1ffac90196fdf2a4fe2f/stats \
  -H "Authorization: Bearer $TOKEN"
```

---

## ⚠️ Notas Importantes

1. **Slug é gerado automaticamente** a partir do `name` e não pode ser alterado diretamente
2. **Billing fields** (billing_day, billing_due_date, payment_status) devem ser gerenciados via `/api/billing/*`
3. **Status 'suspended'** impede acesso de usuários da empresa (exceto machine)
4. **max_users** limita quantos usuários podem ser criados na empresa
5. **settings** é um campo livre (Hash) para configurações customizadas
6. **PATCH** também funciona (redireciona para PUT internamente)

---

## 🔄 Planos Disponíveis

| Plano | Código | Usuários Padrão | Preço Sugerido |
|-------|--------|-----------------|----------------|
| Básico | `basic` | 5 | R$ 49/mês |
| Profissional | `professional` | 15 | R$ 99/mês |
| Premium | `premium` | 30 | R$ 199/mês |
| Enterprise | `enterprise` | Ilimitado | Sob consulta |

---

## 🚀 Próximos Passos

- [ ] Sistema de features modulares
- [ ] Histórico de alterações (audit log)
- [ ] Webhook para notificar alterações
- [ ] Endpoint para upgrade/downgrade de plano com cálculo proporcional
