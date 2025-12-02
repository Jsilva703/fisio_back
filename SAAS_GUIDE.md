# 🚀 Sistema SaaS Multi-Tenant - Guia Completo

## 📋 Estrutura do Sistema

Seu backend agora é um **SaaS Multi-Tenant** onde:
- Cada **empresa (company)** tem seus próprios dados isolados
- Usuários **machine** gerenciam todas as empresas
- Usuários **admin/user** só veem dados da sua empresa

## 🏢 Hierarquia

```
┌─────────────────────────────────────┐
│          MACHINE (Super Admin)      │
│   - Cria e gerencia empresas        │
│   - Vê estatísticas globais         │
│   - Não acessa dados das empresas   │
└──────────────┬──────────────────────┘
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼────┐          ┌─────▼───┐
│Company1│          │Company2 │
│  Fisio │          │  Pilates│
└───┬────┘          └────┬────┘
    │                    │
┌───▼───────┐      ┌─────▼────────┐
│ Users     │      │ Users        │
│ Admin     │      │ Admin        │
│ User      │      │ User         │
├───────────┤      ├──────────────┤
│Appointments│      │Appointments  │
│Schedulings│      │Schedulings   │
└───────────┘      └──────────────┘
```

## 🔧 Setup Inicial

### 1. Criar usuário Machine (apenas uma vez)

```bash
curl -X POST http://localhost:9292/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Machine System",
    "email": "machine@sistema.com",
    "password": "machine_super_senha_123",
    "role": "machine"
  }'
```

**Resposta:**
```json
{
  "status": "success",
  "token": "eyJhbGc...",
  "user": {
    "id": "...",
    "email": "machine@sistema.com",
    "role": "machine"
  }
}
```

### 2. Login como Machine

```bash
MACHINE_TOKEN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"machine@sistema.com","password":"machine_super_senha_123"}' \
  | jq -r '.token')

echo "Token Machine: $MACHINE_TOKEN"
```

## 🏢 Gerenciamento de Empresas (Role: machine)

### Criar Empresa

```bash
curl -X POST http://localhost:9292/api/companies \
  -H "Authorization: Bearer $MACHINE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Clínica Fisio Saúde",
    "email": "contato@fisio.com",
    "phone": "(11) 98888-7777",
    "cnpj": "12.345.678/0001-90",
    "address": "Rua das Flores, 123",
    "plan": "premium",
    "max_users": 10
  }'
```

**Planos disponíveis:**
- `basic` - Plano básico (5 usuários padrão)
- `premium` - Plano premium
- `enterprise` - Plano enterprise

### Listar Todas as Empresas

```bash
curl -X GET http://localhost:9292/api/companies \
  -H "Authorization: Bearer $MACHINE_TOKEN"
```

**Resposta:**
```json
{
  "status": "success",
  "total": 2,
  "companies": [
    {
      "id": "674e...",
      "name": "Clínica Fisio Saúde",
      "slug": "clinica-fisio-saude",
      "email": "contato@fisio.com",
      "plan": "premium",
      "status": "active",
      "users_count": 3,
      "appointments_count": 45,
      "schedulings_count": 12
    }
  ]
}
```

### Buscar Empresa por ID

```bash
curl -X GET http://localhost:9292/api/companies/COMPANY_ID \
  -H "Authorization: Bearer $MACHINE_TOKEN"
```

### Atualizar Empresa

```bash
curl -X PATCH http://localhost:9292/api/companies/COMPANY_ID \
  -H "Authorization: Bearer $MACHINE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "suspended",
    "plan": "enterprise",
    "max_users": 20
  }'
```

**Status disponíveis:**
- `active` - Empresa ativa
- `inactive` - Empresa inativa
- `suspended` - Empresa suspensa

### Estatísticas de uma Empresa

```bash
curl -X GET http://localhost:9292/api/companies/COMPANY_ID/stats \
  -H "Authorization: Bearer $MACHINE_TOKEN"
```

**Resposta:**
```json
{
  "status": "success",
  "company_name": "Clínica Fisio Saúde",
  "stats": {
    "users": {
      "total": 3,
      "max_allowed": 10,
      "by_role": {
        "admin": 1,
        "user": 2
      }
    },
    "appointments": {
      "total": 45,
      "by_status": {
        "scheduled": 30,
        "completed": 15
      },
      "total_revenue": 6750.0
    },
    "schedulings": {
      "total": 12
    }
  }
}
```

### Dashboard Machine (Visão Geral do SaaS)

```bash
curl -X GET http://localhost:9292/api/machine/dashboard \
  -H "Authorization: Bearer $MACHINE_TOKEN"
```

**Resposta:**
```json
{
  "status": "success",
  "message": "Dashboard Machine - SaaS Overview",
  "overview": {
    "companies": {
      "total": 5,
      "active": 4,
      "inactive": 0,
      "suspended": 1,
      "by_plan": {
        "basic": 2,
        "premium": 2,
        "enterprise": 1
      }
    },
    "users": {
      "total": 23
    },
    "appointments": {
      "total": 234,
      "total_revenue": 35100.50
    }
  },
  "top_companies": [
    {
      "id": "...",
      "name": "Clínica Fisio Saúde",
      "plan": "premium",
      "appointments_count": 89,
      "users_count": 5,
      "total_revenue": 13350.0
    }
  ]
}
```

## 👥 Gerenciamento de Usuários das Empresas

### Criar Usuário para uma Empresa

```bash
# Primeiro, pegue o company_id da empresa
COMPANY_ID="674e..."

curl -X POST http://localhost:9292/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Dr. João Silva",
    "email": "joao@fisio.com",
    "password": "senha123",
    "role": "admin",
    "company_id": "'$COMPANY_ID'"
  }'
```

**Importante:** 
- `company_id` é **obrigatório** para roles `user` e `admin`
- O sistema valida se a empresa está ativa
- O sistema valida se há vagas disponíveis (max_users)

### Login de Usuário da Empresa

```bash
USER_TOKEN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"joao@fisio.com","password":"senha123"}' \
  | jq -r '.token')

echo "Token User: $USER_TOKEN"
```

**O token JWT contém:**
```json
{
  "user_id": "...",
  "email": "joao@fisio.com",
  "role": "admin",
  "company_id": "674e..."  // ← IMPORTANTE
}
```

## 🔒 Isolamento de Dados (Multi-Tenancy)

### Usuários veem APENAS dados da sua empresa

```bash
# Usuário da Empresa 1
curl -X GET http://localhost:9292/api/appointments \
  -H "Authorization: Bearer $USER_TOKEN"

# Retorna APENAS appointments da Empresa 1
```

```bash
# Usuário da Empresa 2 (outro token)
curl -X GET http://localhost:9292/api/appointments \
  -H "Authorization: Bearer $OTHER_USER_TOKEN"

# Retorna APENAS appointments da Empresa 2
```

### Criar Agendamento (automaticamente associado à empresa)

```bash
curl -X POST http://localhost:9292/api/appointments \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "Maria Santos",
    "patient_phone": "(11) 99999-8888",
    "patiente_document": "123.456.789-00",
    "type": "clinic",
    "appointment_date": "2025-12-10T14:00:00-03:00",
    "price": 150.0
  }'
```

**O `company_id` é adicionado automaticamente do token!**

## 🎯 Fluxo Completo de Uso

### 1. Machine cria empresa

```bash
# Login machine
MACHINE_TOKEN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"machine@sistema.com","password":"machine123"}' \
  | jq -r '.token')

# Criar empresa
COMPANY_RESPONSE=$(curl -s -X POST http://localhost:9292/api/companies \
  -H "Authorization: Bearer $MACHINE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nova Clínica",
    "email": "nova@clinica.com",
    "plan": "basic"
  }')

COMPANY_ID=$(echo $COMPANY_RESPONSE | jq -r '.company.id')
echo "Company ID: $COMPANY_ID"
```

### 2. Criar admin da empresa

```bash
curl -X POST http://localhost:9292/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin Nova Clínica",
    "email": "admin@nova.com",
    "password": "admin123",
    "role": "admin",
    "company_id": "'$COMPANY_ID'"
  }'
```

### 3. Admin loga e cria agendamento

```bash
# Login admin
ADMIN_TOKEN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nova.com","password":"admin123"}' \
  | jq -r '.token')

# Criar agendamento (company_id automático)
curl -X POST http://localhost:9292/api/appointments \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "Paciente Teste",
    "patient_phone": "(11) 98888-7777",
    "patiente_document": "123.456.789-00",
    "type": "clinic",
    "appointment_date": "2025-12-10T14:00:00-03:00",
    "price": 150.0
  }'
```

### 4. Machine monitora tudo

```bash
# Ver dashboard global
curl -X GET http://localhost:9292/api/machine/dashboard \
  -H "Authorization: Bearer $MACHINE_TOKEN"

# Ver stats da empresa específica
curl -X GET http://localhost:9292/api/companies/$COMPANY_ID/stats \
  -H "Authorization: Bearer $MACHINE_TOKEN"
```

## 📊 Resumo de Rotas

| Rota | Método | Quem Acessa | Descrição |
|------|--------|-------------|-----------|
| `/api/auth/register` | POST | Todos | Registrar (machine não precisa company_id) |
| `/api/auth/login` | POST | Todos | Login |
| `/api/machine/dashboard` | GET | Machine | Dashboard global do SaaS |
| `/api/companies` | GET/POST | Machine | Listar/Criar empresas |
| `/api/companies/:id` | GET/PATCH/DELETE | Machine | Gerenciar empresa |
| `/api/companies/:id/stats` | GET | Machine | Estatísticas da empresa |
| `/api/appointments` | * | Admin/User | CRUD agendamentos (filtrado por company) |
| `/api/schedulings` | * | Admin/User | CRUD agendas (filtrado por company) |

## 🛡️ Segurança

✅ **Isolamento garantido:**
- Usuários **NUNCA** veem dados de outras empresas
- `company_id` vem do token JWT (não pode ser falsificado)
- Machine **NÃO PODE** acessar appointments/schedulings
- Admin/User **NÃO PODEM** acessar rotas de machine/companies

✅ **Validações:**
- Empresa deve estar `active` para login
- Limite de usuários por empresa (max_users)
- Token JWT expira em 24h
- CNPJ único por empresa

## 💡 Dicas de Implementação no Frontend

### React - Context para Multi-Tenancy

```jsx
// contexts/TenantContext.jsx
import { createContext, useContext, useEffect, useState } from 'react';

const TenantContext = createContext();

export function TenantProvider({ children }) {
  const [user, setUser] = useState(null);
  const [companyId, setCompanyId] = useState(null);

  useEffect(() => {
    const storedUser = localStorage.getItem('user');
    if (storedUser) {
      const userData = JSON.parse(storedUser);
      setUser(userData);
      setCompanyId(userData.company_id);
    }
  }, []);

  return (
    <TenantContext.Provider value={{ user, companyId }}>
      {children}
    </TenantContext.Provider>
  );
}

export const useTenant = () => useContext(TenantContext);
```

### Roteamento baseado em Role

```jsx
// App.jsx
function App() {
  const { user } = useTenant();

  if (!user) return <Login />;

  if (user.role === 'machine') {
    return <MachineApp />;  // Dashboard machine
  }

  return <ClinicApp />;  // Dashboard clínica
}
```

Seu sistema agora é um **SaaS completo e escalável**! 🚀
