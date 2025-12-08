# 🔥 Todos os CURLs - Fisio Back API

**Base URL:** `http://localhost:9292` ou `https://fisio-back.onrender.com`

---

## 🔐 1. AUTENTICAÇÃO

### Login
```bash
curl -X POST 'http://localhost:9292/api/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "admin@gmail.com",
    "password": "senha123"
  }'
```

### Registrar Usuário
```bash
curl -X POST 'http://localhost:9292/api/auth/register' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "João Silva",
    "email": "joao@empresa.com",
    "password": "senha123",
    "role": "admin",
    "company_id": "693012a4a1a9fe80823ebf9e"
  }'
```

### Ver Usuário Logado
```bash
curl -X GET 'http://localhost:9292/api/auth/me' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

---

## 🏢 2. EMPRESAS (COMPANIES)

### Listar Empresas (Machine only)
```bash
curl -X GET 'http://localhost:9292/api/companies' \
  -H 'Authorization: Bearer TOKEN_MACHINE'
```

### Ver Empresa por ID
```bash
curl -X GET 'http://localhost:9292/api/companies/693012a4a1a9fe80823ebf9e' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Ver Estatísticas da Empresa
```bash
curl -X GET 'http://localhost:9292/api/companies/693012a4a1a9fe80823ebf9e/stats' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Criar Empresa (Machine only)
```bash
curl -X POST 'http://localhost:9292/api/companies' \
  -H 'Authorization: Bearer TOKEN_MACHINE' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Clínica Exemplo",
    "email": "contato@clinica.com",
    "phone": "(11) 98888-9999",
    "plan": "basic",
    "cnpj": "12.345.678/0001-99",
    "address": "Rua Exemplo, 123"
  }'
```

### Atualizar Empresa
```bash
curl -X PUT 'http://localhost:9292/api/companies/693012a4a1a9fe80823ebf9e' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Nova Clínica",
    "plan": "premium",
    "max_users": 15
  }'
```

### Deletar Empresa (Machine only)
```bash
curl -X DELETE 'http://localhost:9292/api/companies/693012a4a1a9fe80823ebf9e' \
  -H 'Authorization: Bearer TOKEN_MACHINE'
```

---

## 👥 3. USUÁRIOS (USERS)

### Listar Usuários da Empresa
```bash
curl -X GET 'http://localhost:9292/api/users' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Ver Usuário por ID
```bash
curl -X GET 'http://localhost:9292/api/users/6931f2ad1c63f14b928fd375' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Criar Usuário (Admin only)
```bash
curl -X POST 'http://localhost:9292/api/users' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Maria Silva",
    "email": "maria@empresa.com",
    "password": "senha123",
    "role": "user"
  }'
```

### Atualizar Usuário
```bash
curl -X PUT 'http://localhost:9292/api/users/6931f2ad1c63f14b928fd375' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Maria Silva Santos",
    "status": "inactive"
  }'
```

### Deletar Usuário (Admin only)
```bash
curl -X DELETE 'http://localhost:9292/api/users/6931f2ad1c63f14b928fd375' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

---

## 👤 4. PACIENTES (PATIENTS)

### Listar Pacientes
```bash
curl -X GET 'http://localhost:9292/api/patients' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Listar com Filtros
```bash
curl -X GET 'http://localhost:9292/api/patients?page=1&per_page=20&search=Maria&status=active' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Buscar Paciente por CPF
```bash
curl -X GET 'http://localhost:9292/api/patients?search=12345678900' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Ver Paciente por ID
```bash
curl -X GET 'http://localhost:9292/api/patients/6931c8f01ea92af0a8a9a323' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Criar Paciente
```bash
curl -X POST 'http://localhost:9292/api/patients' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "João Victor Silva",
    "email": "joao@email.com",
    "phone": "11911031972",
    "cpf": "123.456.789-00",
    "rg": "12.345.678-9",
    "birth_date": "2001-05-05",
    "gender": "male",
    "blood_type": "O+",
    "address": {
      "street": "Rua das Flores",
      "number": "123",
      "city": "São Paulo",
      "state": "SP",
      "zip_code": "01234-567"
    },
    "allergies": ["Dipirona"],
    "medications": ["Losartana 50mg"],
    "health_insurance": {
      "name": "Unimed",
      "number": "123456789",
      "validity": "2026-12-31"
    },
    "emergency_contact": {
      "name": "Maria Silva",
      "relationship": "Mãe",
      "phone": "(11) 98888-7777"
    }
  }'
```

### Atualizar Paciente
```bash
curl -X PUT 'http://localhost:9292/api/patients/6931c8f01ea92af0a8a9a323' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "phone": "(11) 99999-8888",
    "email": "joao.novo@email.com"
  }'
```

### Ver Histórico do Paciente
```bash
curl -X GET 'http://localhost:9292/api/patients/6931c8f01ea92af0a8a9a323/history' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Deletar Paciente
```bash
curl -X DELETE 'http://localhost:9292/api/patients/6931c8f01ea92af0a8a9a323' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

---

## 🗓️ 5. AGENDAS (SCHEDULINGS)

### Listar Agendas
```bash
curl -X GET 'http://localhost:9292/api/schedulings' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Ver Agenda por Data
```bash
curl -X GET 'http://localhost:9292/api/schedulings/2025-12-08' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Criar Agenda
```bash
curl -X POST 'http://localhost:9292/api/schedulings' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "date": "2025-12-08",
    "slots": ["09:00", "10:00", "11:00", "14:00", "15:00", "16:00"]
  }'
```

### Deletar Agenda
```bash
curl -X DELETE 'http://localhost:9292/api/schedulings/2025-12-08' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

---

## 📅 6. CONSULTAS (APPOINTMENTS)

### Listar Consultas
```bash
curl -X GET 'http://localhost:9292/api/appointments' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Ver Consulta por ID
```bash
curl -X GET 'http://localhost:9292/api/appointments/6931d58315eb23a393465976' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Criar Consulta
```bash
curl -X POST 'http://localhost:9292/api/appointments' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "patient_id": "6931c8f01ea92af0a8a9a323",
    "appointment_date": "2025-12-08T09:00:00-03:00",
    "type": "clinic",
    "address": "",
    "price": 150.00
  }'
```

### Reagendar Consulta
```bash
curl -X PATCH 'http://localhost:9292/api/appointments/6931d58315eb23a393465976' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "appointment_date": "2025-12-08T15:00:00-03:00"
  }'
```

### Atualizar Status/Preço da Consulta
```bash
curl -X PATCH 'http://localhost:9292/api/appointments/6931d58315eb23a393465976' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "price": 180.00,
    "status": "confirmed",
    "payment_status": "paid"
  }'
```

### Cancelar Consulta
```bash
curl -X DELETE 'http://localhost:9292/api/appointments/6931d58315eb23a393465976' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

---

## 📋 7. PRONTUÁRIOS (MEDICAL RECORDS)

### Listar Prontuários do Paciente
```bash
curl -X GET 'http://localhost:9292/api/medical-records/patient/6931c8f01ea92af0a8a9a323' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Ver Prontuário por ID
```bash
curl -X GET 'http://localhost:9292/api/medical-records/692fc1234567890abcdef99' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

### Criar Prontuário (Anamnese)
```bash
curl -X POST 'http://localhost:9292/api/medical-records' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "patient_id": "6931c8f01ea92af0a8a9a323",
    "record_type": "anamnesis",
    "date": "2025-12-08",
    "time": "09:00",
    "chief_complaint": "Dor lombar há 3 semanas",
    "history": "Paciente relata dor que piora ao levantar objetos pesados",
    "physical_exam": "Limitação de movimento na flexão",
    "diagnosis": "Lombalgia mecânica aguda",
    "treatment_plan": "Fisioterapia 3x por semana",
    "procedures": ["Massagem terapêutica", "TENS"],
    "vital_signs": {
      "blood_pressure": "120/80",
      "heart_rate": 75,
      "temperature": 36.5,
      "weight": 68.0,
      "height": 170
    },
    "pain_scale": 7,
    "goals": ["Reduzir dor"],
    "next_steps": "Retornar em 3 dias",
    "status": "open"
  }'
```

### Atualizar Prontuário (Evolução)
```bash
curl -X PUT 'http://localhost:9292/api/medical-records/692fc1234567890abcdef99' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "evolution": "Paciente retorna após 3 sessões. Relata melhora de 60% da dor",
    "pain_scale": 3,
    "procedures": ["Massagem", "Alongamento", "TENS"],
    "next_steps": "Continuar tratamento"
  }'
```

### Criar Prontuário de Alta
```bash
curl -X POST 'http://localhost:9292/api/medical-records' \
  -H 'Authorization: Bearer SEU_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "patient_id": "6931c8f01ea92af0a8a9a323",
    "record_type": "discharge",
    "date": "2025-12-15",
    "time": "10:00",
    "chief_complaint": "Alta por melhora completa",
    "evolution": "Paciente completou tratamento com sucesso",
    "diagnosis": "Lombalgia mecânica - CURADO",
    "pain_scale": 0,
    "next_steps": "Alta médica",
    "status": "closed"
  }'
```

### Deletar Prontuário
```bash
curl -X DELETE 'http://localhost:9292/api/medical-records/692fc1234567890abcdef99' \
  -H 'Authorization: Bearer SEU_TOKEN'
```

---

## 🌐 8. APIs PÚBLICAS (Sem Autenticação)

### Ver Dias Disponíveis
```bash
curl -X GET 'http://localhost:9292/api/public/booking/693012a4a1a9fe80823ebf9e/available-days'
```

### Ver Horários Disponíveis
```bash
curl -X GET 'http://localhost:9292/api/public/booking/693012a4a1a9fe80823ebf9e/available-slots/2025-12-08'
```

### Ver Info da Empresa
```bash
curl -X GET 'http://localhost:9292/api/public/booking/693012a4a1a9fe80823ebf9e/info'
```

### Verificar se Paciente Existe
```bash
curl -X GET 'http://localhost:9292/api/public/booking/693012a4a1a9fe80823ebf9e/check-patient?cpf=12345678900'
```

### Registrar Paciente (Público)
```bash
curl -X POST 'http://localhost:9292/api/public/booking/693012a4a1a9fe80823ebf9e/register-patient' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "João Silva",
    "email": "joao@email.com",
    "phone": "(11) 91234-5678",
    "cpf": "123.456.789-00"
  }'
```

### Agendar Consulta (Público)
```bash
curl -X POST 'http://localhost:9292/api/public/booking/693012a4a1a9fe80823ebf9e/book-appointment' \
  -H 'Content-Type: application/json' \
  -d '{
    "patient_name": "João Silva",
    "patient_phone": "(11) 91234-5678",
    "patiente_document": "123.456.789-00",
    "patient_email": "joao@email.com",
    "appointment_date": "2025-12-08T09:00:00-03:00",
    "type": "clinic"
  }'
```

---

## 💰 9. BILLING (Machine Only)

### Ver Empresas com Pagamento Atrasado
```bash
curl -X GET 'http://localhost:9292/api/billing/overdue' \
  -H 'Authorization: Bearer TOKEN_MACHINE'
```

### Ver Pagamentos Pendentes
```bash
curl -X GET 'http://localhost:9292/api/billing/pending' \
  -H 'Authorization: Bearer TOKEN_MACHINE'
```

### Ver Estatísticas de Billing
```bash
curl -X GET 'http://localhost:9292/api/billing/stats' \
  -H 'Authorization: Bearer TOKEN_MACHINE'
```

### Marcar Pagamento como Pago
```bash
curl -X POST 'http://localhost:9292/api/billing/693012a4a1a9fe80823ebf9e/mark-paid' \
  -H 'Authorization: Bearer TOKEN_MACHINE'
```

### Verificar Pagamentos Atrasados
```bash
curl -X POST 'http://localhost:9292/api/billing/run-check' \
  -H 'Authorization: Bearer TOKEN_MACHINE'
```

---

## 🏥 10. HEALTH CHECK

### Verificar Status da API
```bash
curl -X GET 'http://localhost:9292/health'
```

**Resposta:**
```json
{
  "status": "OK",
  "db": "Connected"
}
```

---

## 📝 NOTAS IMPORTANTES

### Formatos de Data
- **Data:** `YYYY-MM-DD` (ex: `2025-12-08`)
- **Hora:** `HH:MM` (ex: `09:00`)
- **Data/Hora completa:** `YYYY-MM-DDTHH:MM:SS-03:00` (ex: `2025-12-08T09:00:00-03:00`)

### Valores Aceitos
- **Gender:** `male`, `female`, `other`
- **Blood Type:** `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`
- **Record Type:** `anamnesis`, `evolution`, `discharge`
- **Status:** `active`, `inactive`
- **Appointment Status:** `scheduled`, `confirmed`, `completed`, `cancelled`
- **Payment Status:** `pending`, `paid`, `cancelled`
- **Role:** `user`, `admin`, `machine`

### Headers Necessários
```
Authorization: Bearer SEU_TOKEN
Content-Type: application/json
```

---

**Total de Endpoints:** 52+ 🚀
