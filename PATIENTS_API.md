# 🏥 API de Pacientes e Prontuários - PhysioCore

## 📋 Índice
1. [API de Pacientes](#api-de-pacientes)
2. [API de Prontuários Médicos](#api-de-prontuários-médicos)

---

# API de Pacientes

## Base URL
```
/api/patients
```

**Autenticação**: Todos os usuários autenticados (admin, user, machine)
**Isolamento**: Cada empresa vê apenas seus pacientes (exceto machine)

---

## Endpoints

### 1. Listar Pacientes
**GET** `/api/patients`

**Query Parameters:**
- `company_id` (String, apenas machine): Filtrar por empresa
- `status` (String): Filtrar por status (`active` | `inactive`)
- `search` (String): Buscar por nome, email, phone ou CPF
- `page` (Integer, padrão: 1): Página
- `per_page` (Integer, padrão: 20): Itens por página

**Response 200:**
```json
{
  "status": "success",
  "total": 15,
  "page": 1,
  "per_page": 20,
  "total_pages": 1,
  "patients": [
    {
      "id": "692f582df9186f4757bc467d",
      "name": "João Silva",
      "email": "joao@email.com",
      "phone": "(11) 98765-4321",
      "cpf": "123.456.789-00",
      "birth_date": "1985-05-15",
      "age": 40,
      "gender": "male",
      "status": "active",
      "company_id": "692f28e170ed81276cf503df",
      "total_appointments": 5,
      "last_appointment": "2025-12-01",
      "created_at": "2025-12-02T18:20:45.783-03:00"
    }
  ]
}
```

---

### 2. Buscar Paciente por ID
**GET** `/api/patients/:id`

**Response 200:**
```json
{
  "status": "success",
  "patient": {
    "id": "692f582df9186f4757bc467d",
    "company_id": "692f28e170ed81276cf503df",
    "name": "João Silva",
    "email": "joao@email.com",
    "phone": "(11) 98765-4321",
    "cpf": "123.456.789-00",
    "rg": "12.345.678-9",
    "birth_date": "1985-05-15",
    "age": 40,
    "gender": "male",
    "address": {
      "street": "Rua Exemplo",
      "number": "123",
      "complement": "Apto 45",
      "neighborhood": "Centro",
      "city": "São Paulo",
      "state": "SP",
      "zip_code": "01234-567"
    },
    "blood_type": "A+",
    "allergies": ["Dipirona", "Penicilina"],
    "medications": ["Paracetamol 500mg"],
    "health_insurance": {
      "provider": "Unimed",
      "plan": "Premium",
      "card_number": "123456789"
    },
    "emergency_contact": {
      "name": "Maria Silva",
      "relationship": "Esposa",
      "phone": "(11) 99999-8888"
    },
    "status": "active",
    "notes": "Paciente colaborativo, boa evolução",
    "source": "manual",
    "total_appointments": 5,
    "last_appointment": "2025-12-01",
    "created_at": "2025-12-02T18:20:45.783-03:00",
    "updated_at": "2025-12-02T18:20:45.783-03:00"
  }
}
```

---

### 3. Criar Paciente
**POST** `/api/patients`

**Request Body:**
```json
{
  "company_id": "692f28e170ed81276cf503df",
  "name": "João Silva",
  "phone": "(11) 98765-4321",
  "email": "joao@email.com",
  "cpf": "123.456.789-00",
  "rg": "12.345.678-9",
  "birth_date": "1985-05-15",
  "gender": "male",
  "address": {
    "street": "Rua Exemplo",
    "number": "123",
    "complement": "Apto 45",
    "neighborhood": "Centro",
    "city": "São Paulo",
    "state": "SP",
    "zip_code": "01234-567"
  },
  "blood_type": "A+",
  "allergies": ["Dipirona"],
  "medications": ["Paracetamol 500mg"],
  "health_insurance": {
    "provider": "Unimed",
    "plan": "Premium",
    "card_number": "123456789"
  },
  "emergency_contact": {
    "name": "Maria Silva",
    "relationship": "Esposa",
    "phone": "(11) 99999-8888"
  },
  "notes": "Paciente encaminhado por ortopedista"
}
```

**Campos Obrigatórios:**
- `name` (String)
- `phone` (String)
- `company_id` (String, apenas machine)

**Campos Opcionais:**
- `email` (String)
- `cpf` (String) - Único por empresa
- `rg` (String)
- `birth_date` (String, formato: YYYY-MM-DD)
- `gender` (String): `male` | `female` | `other`
- `address` (Hash)
- `blood_type` (String): `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`
- `allergies` (Array de Strings)
- `medications` (Array de Strings)
- `health_insurance` (Hash)
- `emergency_contact` (Hash)
- `notes` (String)
- `source` (String): `manual` | `online_booking` | `referral`

**Response 201:**
```json
{
  "status": "success",
  "message": "Paciente criado com sucesso",
  "patient": { ... }
}
```

---

### 4. Atualizar Paciente
**PUT** `/api/patients/:id`

Todos os campos são opcionais. Envie apenas os que deseja atualizar.

**Request Body:**
```json
{
  "phone": "(11) 91234-5678",
  "address": {
    "street": "Nova Rua",
    "number": "456"
  },
  "status": "inactive"
}
```

**Response 200:**
```json
{
  "status": "success",
  "message": "Paciente atualizado com sucesso",
  "patient": { ... }
}
```

---

### 5. Deletar Paciente
**DELETE** `/api/patients/:id`

**Atenção**: Não permite deletar se houver histórico (consultas ou prontuários).

**Response 200:**
```json
{
  "status": "success",
  "message": "Paciente deletado com sucesso"
}
```

**Response 409 (Conflito):**
```json
{
  "error": "Não é possível deletar paciente com histórico",
  "medical_records_count": 5,
  "appointments_count": 3,
  "suggestion": "Altere o status para 'inactive' ao invés de deletar"
}
```

---

### 6. Histórico do Paciente
**GET** `/api/patients/:id/history`

Retorna consultas e prontuários do paciente.

**Response 200:**
```json
{
  "status": "success",
  "patient": {
    "id": "692f582df9186f4757bc467d",
    "name": "João Silva",
    "age": 40
  },
  "appointments": [
    {
      "id": "...",
      "date": "2025-12-01",
      "time": "14:00",
      "status": "completed",
      "procedure": "Fisioterapia"
    }
  ],
  "medical_records": [
    {
      "id": "...",
      "date": "2025-12-01",
      "time": "14:30",
      "record_type": "evolution",
      "chief_complaint": "Melhora da dor lombar",
      "professional": "Dr. João"
    }
  ]
}
```

---

# API de Prontuários Médicos

## Base URL
```
/api/medical-records
```

---

## Endpoints

### 1. Listar Prontuários de um Paciente
**GET** `/api/medical-records/patient/:patient_id`

**Response 200:**
```json
{
  "status": "success",
  "patient": {
    "id": "692f582df9186f4757bc467d",
    "name": "João Silva"
  },
  "total": 3,
  "medical_records": [
    {
      "id": "692f5845f9186f4757bc467f",
      "date": "2025-12-02",
      "time": "18:21",
      "record_type": "anamnesis",
      "chief_complaint": "Dor lombar há 3 meses",
      "diagnosis": "Lombalgia mecânica",
      "pain_scale": 7,
      "status": "open",
      "professional": "Dr. João",
      "created_by_id": "692f1e0cc9c0c64069141b2e",
      "created_at": "2025-12-02T18:21:09.176-03:00",
      "is_recent": true
    }
  ]
}
```

---

### 2. Buscar Prontuário por ID
**GET** `/api/medical-records/:id`

**Response 200:**
```json
{
  "status": "success",
  "medical_record": {
    "id": "692f5845f9186f4757bc467f",
    "patient": {
      "id": "692f582df9186f4757bc467d",
      "name": "João Silva",
      "age": 40
    },
    "company_id": "692f28e170ed81276cf503df",
    "created_by": {
      "id": "692f1e0cc9c0c64069141b2e",
      "name": "Dr. João"
    },
    "appointment_id": null,
    "record_type": "anamnesis",
    "date": "2025-12-02",
    "time": "18:21",
    "chief_complaint": "Dor lombar há 3 meses",
    "history": "Paciente relata dor lombar iniciada após esforço físico",
    "physical_exam": "Tensão muscular em paravertebrais L3-L5",
    "diagnosis": "Lombalgia mecânica",
    "treatment_plan": "Fisioterapia 3x por semana",
    "evolution": null,
    "procedures": ["Alongamento", "Fortalecimento"],
    "vital_signs": {
      "blood_pressure": "120/80",
      "heart_rate": "72 bpm"
    },
    "tests": [],
    "pain_scale": 7,
    "goals": ["Reduzir dor", "Melhorar postura"],
    "next_steps": "Retorno em 7 dias",
    "attachments": [],
    "status": "open",
    "notes": null,
    "is_recent": true,
    "created_at": "2025-12-02T18:21:09.176-03:00",
    "updated_at": "2025-12-02T18:21:09.176-03:00"
  }
}
```

---

### 3. Criar Prontuário
**POST** `/api/medical-records`

**Request Body:**
```json
{
  "patient_id": "692f582df9186f4757bc467d",
  "record_type": "evolution",
  "date": "2025-12-02",
  "time": "14:30",
  "chief_complaint": "Melhora da dor lombar",
  "history": "Paciente relata melhora significativa após 3 sessões",
  "physical_exam": "Redução da tensão muscular",
  "diagnosis": "Lombalgia mecânica em tratamento",
  "treatment_plan": "Continuar fisioterapia 2x por semana",
  "evolution": "Paciente apresentou boa evolução, redução de 50% da dor",
  "procedures": ["Alongamento", "TENS", "Fortalecimento"],
  "vital_signs": {
    "blood_pressure": "120/80",
    "heart_rate": "70 bpm",
    "weight": "75 kg"
  },
  "tests": ["Teste de Schober: 15cm"],
  "pain_scale": 3,
  "goals": ["Reduzir dor para 0-2", "Retornar às atividades"],
  "next_steps": "Orientações de exercícios domiciliares",
  "notes": "Paciente muito colaborativo",
  "appointment_id": "..."
}
```

**Campos Obrigatórios:**
- `patient_id` (String)

**Campos Opcionais:**
- `record_type` (String): `anamnesis` | `evolution` | `discharge` (padrão: `evolution`)
- `date` (String, YYYY-MM-DD) - Se não enviado, usa data atual
- `time` (String, HH:MM) - Se não enviado, usa hora atual
- `chief_complaint` (String)
- `history` (String)
- `physical_exam` (String)
- `diagnosis` (String)
- `treatment_plan` (String)
- `evolution` (String)
- `procedures` (Array)
- `vital_signs` (Hash)
- `tests` (Array)
- `pain_scale` (Integer 0-10)
- `goals` (Array)
- `next_steps` (String)
- `attachments` (Array)
- `notes` (String)
- `appointment_id` (String) - Vincular com consulta

**Response 201:**
```json
{
  "status": "success",
  "message": "Prontuário criado com sucesso",
  "medical_record": { ... }
}
```

---

### 4. Atualizar Prontuário
**PUT** `/api/medical-records/:id`

Todos os campos são opcionais.

**Response 200:**
```json
{
  "status": "success",
  "message": "Prontuário atualizado com sucesso",
  "medical_record": { ... }
}
```

---

### 5. Deletar Prontuário
**DELETE** `/api/medical-records/:id`

**Permissão**: Apenas o criador do prontuário ou machine pode deletar.

**Response 200:**
```json
{
  "status": "success",
  "message": "Prontuário deletado com sucesso"
}
```

---

### 6. Buscar Prontuários por Período
**GET** `/api/medical-records/company/period`

**Query Parameters:**
- `start_date` (String, YYYY-MM-DD): Data inicial **obrigatório**
- `end_date` (String, YYYY-MM-DD): Data final **obrigatório**
- `company_id` (String, apenas machine): Filtrar por empresa

**Response 200:**
```json
{
  "status": "success",
  "period": {
    "start_date": "2025-12-01",
    "end_date": "2025-12-31"
  },
  "total": 25,
  "medical_records": [
    {
      "id": "...",
      "patient_name": "João Silva",
      "patient_id": "...",
      "date": "2025-12-02",
      "time": "14:30",
      "record_type": "evolution",
      "chief_complaint": "Melhora da dor",
      "professional": "Dr. João"
    }
  ]
}
```

---

## 📋 Exemplos de Uso

### Criar Paciente Completo
```bash
curl -X POST http://localhost:9292/api/patients \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "company_id": "692f28e170ed81276cf503df",
    "name": "Maria Santos",
    "phone": "(11) 99999-8888",
    "email": "maria@email.com",
    "cpf": "987.654.321-00",
    "birth_date": "1990-03-20",
    "gender": "female",
    "blood_type": "O+",
    "allergies": ["Dipirona"],
    "emergency_contact": {
      "name": "Pedro Santos",
      "relationship": "Marido",
      "phone": "(11) 98888-7777"
    }
  }'
```

### Buscar Pacientes por Nome
```bash
curl -X GET "http://localhost:9292/api/patients?search=Maria" \
  -H "Authorization: Bearer $TOKEN"
```

### Criar Anamnese (Primeira Consulta)
```bash
curl -X POST http://localhost:9292/api/medical-records \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "692f582df9186f4757bc467d",
    "record_type": "anamnesis",
    "chief_complaint": "Dor no ombro direito há 2 meses",
    "history": "Dor iniciada após queda. Piora com elevação do braço.",
    "physical_exam": "Amplitude de movimento reduzida em 40%",
    "diagnosis": "Tendinite do supraespinhal",
    "treatment_plan": "Fisioterapia 3x semana por 6 semanas",
    "pain_scale": 8,
    "goals": ["Reduzir dor", "Recuperar amplitude", "Retornar ao trabalho"]
  }'
```

### Criar Evolução
```bash
curl -X POST http://localhost:9292/api/medical-records \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "692f582df9186f4757bc467d",
    "record_type": "evolution",
    "evolution": "Paciente com melhora de 60% da dor. Amplitude aumentou 20%.",
    "procedures": ["Ultrassom", "Alongamento", "Fortalecimento"],
    "pain_scale": 3,
    "next_steps": "Continuar tratamento, incluir exercícios resistidos"
  }'
```

### Buscar Prontuários por Período
```bash
curl -X GET "http://localhost:9292/api/medical-records/company/period?start_date=2025-12-01&end_date=2025-12-31" \
  -H "Authorization: Bearer $TOKEN"
```

---

## ⚠️ Notas Importantes

1. **CPF único por empresa**: Não é possível cadastrar 2 pacientes com mesmo CPF na mesma empresa
2. **Cálculo automático de idade**: Calculado a partir do `birth_date`
3. **Prontuários vinculados**: Não é possível deletar paciente com histórico
4. **Permissões**: Profissionais só podem deletar prontuários que criaram
5. **Datas automáticas**: Se não enviar `date` e `time`, sistema usa data/hora atual
6. **Isolamento multi-tenant**: Cada empresa vê apenas seus dados

---

## 🎯 Próximas Features

- [ ] Upload de anexos (exames, documentos)
- [ ] Assinatura digital em prontuários
- [ ] Templates de prontuário por especialidade
- [ ] Relatórios de evolução com gráficos
- [ ] Exportar prontuário em PDF
- [ ] Histórico de alterações (audit log)
- [ ] Busca avançada por diagnóstico/procedimento
