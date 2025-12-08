# 🏥 Fluxo Completo - Visão Empresa (Gestão Interna)

Este guia mostra o fluxo completo de uso do sistema na **visão da empresa**, desde criar agenda até o prontuário médico.

---

## 📋 Índice do Fluxo

1. [Criar agenda de horários](#1-criar-agenda-de-horários)
2. [Criar paciente](#2-criar-paciente)
3. [Listar pacientes](#3-listar-pacientes)
4. [Ver detalhes do paciente](#4-ver-detalhes-do-paciente)
5. [Atualizar dados do paciente](#5-atualizar-dados-do-paciente)
6. [Criar consulta](#6-criar-consulta)
7. [Listar consultas agendadas](#7-listar-consultas-agendadas)
8. [Atualizar consulta (preço/status)](#8-atualizar-consulta-preçostatus)
9. [Criar prontuário (anamnese)](#9-criar-prontuário-anamnese)
10. [Listar prontuários do paciente](#10-listar-prontuários-do-paciente)
11. [Ver detalhes do prontuário](#11-ver-detalhes-do-prontuário)
12. [Atualizar prontuário (evolução)](#12-atualizar-prontuário-evolução)
13. [Ver histórico completo do paciente](#13-ver-histórico-completo-do-paciente)
14. [Criar prontuário de alta](#14-criar-prontuário-de-alta)

---

## 🔑 Autenticação

**⚠️ Todas as APIs abaixo exigem token JWT:**
```
Authorization: Bearer SEU_TOKEN_EMPRESA
```

---

## 🗓️ FASE 1: Gestão de Agendas

### 1. Criar agenda de horários

**Criar slots disponíveis para um dia específico**

```bash
curl -X POST "http://localhost:9292/api/schedulings" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "date": "2025-12-05",
    "slots": ["09:00", "10:00", "11:00", "14:00", "15:00", "16:00"]
  }'
```

**Resposta (201 Created):**
```json
{
  "status": "success",
  "message": "Agenda criada com sucesso",
  "scheduling": {
    "id": "692f7777567890abcdef11",
    "company_id": "692f1ffac90196fdf2a4fe2f",
    "date": "2025-12-05",
    "slots": ["09:00", "10:00", "11:00", "14:00", "15:00", "16:00"],
    "enabled": 0,
    "created_at": "2025-12-04T15:00:00-03:00"
  }
}
```

---

## 👥 FASE 2: Gestão de Pacientes

### 2. Criar paciente

```bash
curl -X POST "http://localhost:9292/api/patients" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Maria Santos",
    "phone": "(11) 91234-5678",
    "cpf": "987.654.321-00",
    "email": "maria@email.com",
    "rg": "12.345.678-9",
    "birth_date": "1990-05-20",
    "gender": "female",
    "address": {
      "street": "Rua das Flores",
      "number": "123",
      "complement": "Apto 45",
      "neighborhood": "Centro",
      "city": "São Paulo",
      "state": "SP",
      "zip_code": "01234-567"
    },
    "blood_type": "O+",
    "allergies": ["Dipirona", "Penicilina"],
    "medications": ["Losartana 50mg"],
    "health_insurance": {
      "name": "Unimed",
      "number": "123456789012345",
      "validity": "2026-12-31"
    },
    "emergency_contact": {
      "name": "José Santos",
      "relationship": "Esposo",
      "phone": "(11) 98888-7777"
    },
    "status": "active"
  }'
```

**Campos obrigatórios:**
- `name` - Nome completo
- `phone` - Telefone
- `cpf` - CPF (único por empresa)

**Resposta (201 Created):**
```json
{
  "status": "success",
  "message": "Paciente criado com sucesso",
  "patient": {
    "id": "692f9a1234567890abcdef12",
    "name": "Maria Santos",
    "email": "maria@email.com",
    "phone": "(11) 91234-5678",
    "cpf": "987.654.321-00",
    "age": 34,
    "status": "active",
    "created_at": "2025-12-04T10:30:00-03:00"
  }
}
```

---

### 3. Listar pacientes

```bash
# Listar todos
curl -X GET "http://localhost:9292/api/patients" \
  -H "Authorization: Bearer eyJhbGc..."

# Com filtros
curl -X GET "http://localhost:9292/api/patients?page=1&per_page=20&search=Maria&status=active" \
  -H "Authorization: Bearer eyJhbGc..."
```

**Query Parameters:**
- `page` - Número da página (default: 1)
- `per_page` - Itens por página (default: 20)
- `search` - Busca por nome, email, telefone ou CPF
- `status` - `active` ou `inactive`

**Resposta:**
```json
{
  "status": "success",
  "total": 15,
  "page": 1,
  "per_page": 20,
  "total_pages": 1,
  "patients": [
    {
      "id": "692f9a1234567890abcdef12",
      "name": "Maria Santos",
      "email": "maria@email.com",
      "phone": "(11) 91234-5678",
      "cpf": "987.654.321-00",
      "birth_date": "1990-05-20",
      "age": 34,
      "gender": "female",
      "blood_type": "O+",
      "status": "active",
      "source": "manual",
      "total_appointments": 0,
      "last_appointment": null,
      "created_at": "2025-12-04T10:30:00-03:00"
    }
  ]
}
```

---

### 4. Ver detalhes do paciente

```bash
curl -X GET "http://localhost:9292/api/patients/692f9a1234567890abcdef12" \
  -H "Authorization: Bearer eyJhbGc..."
```

**Resposta:**
```json
{
  "status": "success",
  "patient": {
    "id": "692f9a1234567890abcdef12",
    "company_id": "692f1ffac90196fdf2a4fe2f",
    "name": "Maria Santos",
    "email": "maria@email.com",
    "phone": "(11) 91234-5678",
    "cpf": "987.654.321-00",
    "rg": "12.345.678-9",
    "birth_date": "1990-05-20",
    "age": 34,
    "gender": "female",
    "address": {
      "street": "Rua das Flores",
      "number": "123",
      "complement": "Apto 45",
      "neighborhood": "Centro",
      "city": "São Paulo",
      "state": "SP",
      "zip_code": "01234-567"
    },
    "blood_type": "O+",
    "allergies": ["Dipirona", "Penicilina"],
    "medications": ["Losartana 50mg"],
    "health_insurance": {
      "name": "Unimed",
      "number": "123456789012345",
      "validity": "2026-12-31"
    },
    "emergency_contact": {
      "name": "José Santos",
      "relationship": "Esposo",
      "phone": "(11) 98888-7777"
    },
    "status": "active",
    "notes": null,
    "source": "manual",
    "total_appointments": 0,
    "last_appointment": null,
    "created_at": "2025-12-04T10:30:00-03:00",
    "updated_at": "2025-12-04T10:30:00-03:00"
  }
}
```

---

### 5. Atualizar dados do paciente

```bash
curl -X PUT "http://localhost:9292/api/patients/692f9a1234567890abcdef12" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "(11) 99999-8888",
    "email": "maria.novo@email.com",
    "address": {
      "street": "Rua Nova",
      "number": "456",
      "city": "São Paulo",
      "state": "SP",
      "zip_code": "01234-999"
    }
  }'
```

**Pode atualizar apenas os campos que mudaram**

**Resposta:**
```json
{
  "status": "success",
  "message": "Paciente atualizado com sucesso",
  "patient": {
    "id": "692f9a1234567890abcdef12",
    "name": "Maria Santos",
    "email": "maria.novo@email.com",
    "phone": "(11) 99999-8888",
    "age": 34
  }
}
```

---

## 📅 FASE 3: Gestão de Consultas

### 6. Criar consulta

```bash
curl -X POST "http://localhost:9292/api/appointments" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "Maria Santos",
    "patient_phone": "(11) 91234-5678",
    "patiente_document": "987.654.321-00",
    "type": "clinic",
    "address": "",
    "appointment_date": "2025-12-05T10:00:00-03:00",
    "price": 150.00
  }'
```

**Campos:**
- `patient_name` - Nome do paciente (obrigatório)
- `patient_phone` - Telefone (obrigatório)
- `patiente_document` - CPF
- `type` - "clinic" ou "home"
- `address` - Endereço (obrigatório se type="home")
- `appointment_date` - Data e hora (formato ISO: YYYY-MM-DDTHH:MM:SS-03:00)
- `price` - Valor da consulta

**Resposta (201 Created):**
```json
{
  "status": "success",
  "agendamento": {
    "id": "692fab9876543210fedcba98",
    "patient_name": "Maria Santos",
    "patient_phone": "(11) 91234-5678",
    "patiente_document": "987.654.321-00",
    "type": "clinic",
    "appointment_date": "2025-12-05T10:00:00-03:00",
    "duration": 60,
    "price": 150.0,
    "status": "scheduled",
    "payment_status": "pending",
    "company_id": "692f1ffac90196fdf2a4fe2f",
    "created_at": "2025-12-04T15:30:00-03:00"
  }
}
```

**⚠️ Importante:** O horário será consumido automaticamente da agenda!

---

### 7. Listar consultas agendadas

```bash
curl -X GET "http://localhost:9292/api/appointments" \
  -H "Authorization: Bearer eyJhbGc..."
```

**Resposta:**
```json
{
  "status": "success",
  "agendamentos": [
    {
      "id": "692fab9876543210fedcba98",
      "patient_id": "692f9a1234567890abcdef12",
      "patient_name": "Maria Santos",
      "patient_phone": "(11) 91234-5678",
      "patiente_document": "987.654.321-00",
      "type": "clinic",
      "procedure": null,
      "address": null,
      "appointment_date": "2025-12-05T10:00:00-03:00",
      "duration": 60,
      "price": 150.0,
      "status": "scheduled",
      "payment_status": "pending",
      "company_id": "692f1ffac90196fdf2a4fe2f",
      "created_at": "2025-12-04T15:30:00-03:00"
    }
  ]
}
```

---

### 8. Atualizar consulta (preço/status)

```bash
curl -X PATCH "http://localhost:9292/api/appointments/692fab9876543210fedcba98" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "price": 180.00,
    "status": "confirmed",
    "payment_status": "paid"
  }'
```

**Campos que podem ser atualizados:**
- `price` - Valor da consulta
- `status` - "scheduled", "confirmed", "completed", "cancelled"
- `payment_status` - "pending", "paid", "cancelled"
- `procedure` - Tipo de procedimento

**Resposta:**
```json
{
  "status": "success",
  "agendamento": {
    "id": "692fab9876543210fedcba98",
    "patient_name": "Maria Santos",
    "price": 180.0,
    "status": "confirmed",
    "payment_status": "paid"
  }
}
```

---

## 📋 FASE 4: Prontuário Médico

### 9. Criar prontuário (anamnese)

**Após a consulta acontecer**

```bash
curl -X POST "http://localhost:9292/api/medical-records" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "692f9a1234567890abcdef12",
    "record_type": "anamnesis",
    "date": "2025-12-05",
    "time": "10:00",
    "chief_complaint": "Dor lombar há 3 semanas",
    "history": "Paciente relata dor que piora ao levantar objetos pesados. Trabalha como auxiliar de depósito.",
    "physical_exam": "Paciente em bom estado geral. Limitação de movimento na flexão. Teste de Lasègue positivo.",
    "diagnosis": "Lombalgia mecânica aguda",
    "treatment_plan": "Fisioterapia 3x por semana durante 4 semanas. Técnicas: massagem terapêutica, alongamento, fortalecimento core.",
    "procedures": ["Massagem terapêutica", "Alongamento lombar", "TENS"],
    "vital_signs": {
      "blood_pressure": "120/80",
      "heart_rate": 75,
      "temperature": 36.5,
      "weight": 68.0,
      "height": 170
    },
    "tests": [],
    "pain_scale": 7,
    "goals": ["Reduzir dor para nível 3 ou menos", "Retornar às atividades laborais"],
    "next_steps": "Retornar em 3 dias para reavaliação",
    "status": "open"
  }'
```

**Campos obrigatórios:**
- `patient_id` - ID do paciente
- `record_type` - "anamnesis", "evolution" ou "discharge"
- `chief_complaint` - Queixa principal

**Resposta (201 Created):**
```json
{
  "status": "success",
  "message": "Prontuário criado com sucesso",
  "medical_record": {
    "id": "692fc1234567890abcdef99",
    "patient_id": "692f9a1234567890abcdef12",
    "record_type": "anamnesis",
    "date": "2025-12-05",
    "time": "10:00",
    "chief_complaint": "Dor lombar há 3 semanas",
    "pain_scale": 7
  }
}
```

---

### 10. Listar prontuários do paciente

```bash
curl -X GET "http://localhost:9292/api/medical-records/patient/692f9a1234567890abcdef12" \
  -H "Authorization: Bearer eyJhbGc..."
```

**Resposta:**
```json
{
  "status": "success",
  "patient": {
    "id": "692f9a1234567890abcdef12",
    "name": "Maria Santos",
    "age": 34
  },
  "total": 3,
  "medical_records": [
    {
      "id": "692fc1234567890abcdef99",
      "record_type": "anamnesis",
      "date": "2025-12-05",
      "time": "10:00",
      "formatted_date": "05/12/2025",
      "chief_complaint": "Dor lombar há 3 semanas",
      "diagnosis": "Lombalgia mecânica aguda",
      "pain_scale": 7,
      "status": "open",
      "created_by_name": "Dr. Silva",
      "created_at": "2025-12-05T10:30:00-03:00"
    }
  ]
}
```

---

### 11. Ver detalhes do prontuário

```bash
curl -X GET "http://localhost:9292/api/medical-records/692fc1234567890abcdef99" \
  -H "Authorization: Bearer eyJhbGc..."
```

**Resposta (todos os campos completos):**
```json
{
  "status": "success",
  "medical_record": {
    "id": "692fc1234567890abcdef99",
    "patient_id": "692f9a1234567890abcdef12",
    "patient_name": "Maria Santos",
    "company_id": "692f1ffac90196fdf2a4fe2f",
    "record_type": "anamnesis",
    "date": "2025-12-05",
    "time": "10:00",
    "formatted_date": "05/12/2025",
    "chief_complaint": "Dor lombar há 3 semanas",
    "history": "Paciente relata dor que piora ao levantar objetos pesados...",
    "physical_exam": "Paciente em bom estado geral. Limitação de movimento...",
    "diagnosis": "Lombalgia mecânica aguda",
    "treatment_plan": "Fisioterapia 3x por semana durante 4 semanas...",
    "evolution": "",
    "procedures": ["Massagem terapêutica", "Alongamento lombar", "TENS"],
    "vital_signs": {
      "blood_pressure": "120/80",
      "heart_rate": 75,
      "temperature": 36.5,
      "weight": 68.0,
      "height": 170
    },
    "tests": [],
    "pain_scale": 7,
    "goals": ["Reduzir dor para nível 3 ou menos", "Retornar às atividades laborais"],
    "next_steps": "Retornar em 3 dias para reavaliação",
    "attachments": [],
    "status": "open",
    "appointment_id": null,
    "created_by_id": "692f1e0cc9c0c64069141b2e",
    "created_by_name": "Dr. Silva",
    "created_at": "2025-12-05T10:30:00-03:00",
    "updated_at": "2025-12-05T10:30:00-03:00"
  }
}
```

---

### 12. Atualizar prontuário (evolução)

**Nas consultas seguintes**

```bash
curl -X PUT "http://localhost:9292/api/medical-records/692fc1234567890abcdef99" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "evolution": "Paciente retorna após 3 sessões. Relata melhora de 60% da dor. Consegue realizar AVDs sem limitação significativa. Mantém desconforto ao levantar peso.",
    "pain_scale": 3,
    "procedures": ["Massagem", "Alongamento", "TENS", "Fortalecimento core"],
    "next_steps": "Continuar tratamento. Próxima sessão em 2 dias. Previsão de alta em 2 semanas."
  }'
```

**Resposta:**
```json
{
  "status": "success",
  "message": "Prontuário atualizado com sucesso",
  "medical_record": {
    "id": "692fc1234567890abcdef99",
    "record_type": "anamnesis",
    "evolution": "Paciente retorna após 3 sessões. Relata melhora de 60% da dor...",
    "pain_scale": 3,
    "updated_at": "2025-12-08T14:30:00-03:00"
  }
}
```

---

### 13. Ver histórico completo do paciente

**Consultas + Prontuários**

```bash
curl -X GET "http://localhost:9292/api/patients/692f9a1234567890abcdef12/history" \
  -H "Authorization: Bearer eyJhbGc..."
```

**Resposta:**
```json
{
  "status": "success",
  "patient": {
    "id": "692f9a1234567890abcdef12",
    "name": "Maria Santos",
    "age": 34
  },
  "appointments": [
    {
      "id": "692fab9876543210fedcba98",
      "date": "2025-12-05",
      "time": "10:00",
      "formatted_date": "05/12/2025 às 10:00",
      "status": "confirmed",
      "procedure": null,
      "price": 180.0,
      "payment_status": "paid"
    }
  ],
  "medical_records": [
    {
      "id": "692fc1234567890abcdef99",
      "record_type": "anamnesis",
      "date": "2025-12-05",
      "chief_complaint": "Dor lombar há 3 semanas",
      "diagnosis": "Lombalgia mecânica aguda",
      "pain_scale": 3,
      "professional_name": "Dr. Silva",
      "created_at": "2025-12-05T10:30:00-03:00"
    }
  ]
}
```

---

### 14. Criar prontuário de alta

**Quando finalizar tratamento**

```bash
curl -X POST "http://localhost:9292/api/medical-records" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "692f9a1234567890abcdef12",
    "record_type": "discharge",
    "date": "2025-12-15",
    "time": "10:00",
    "chief_complaint": "Alta por melhora completa",
    "evolution": "Paciente completou 10 sessões de fisioterapia. Apresenta melhora de 95% do quadro álgico. Realiza todas as AVDs sem limitação. Retornou ao trabalho.",
    "diagnosis": "Lombalgia mecânica - CURADO",
    "procedures": ["Avaliação final", "Orientações posturais"],
    "pain_scale": 0,
    "next_steps": "Alta médica. Orientado a manter exercícios de fortalecimento em casa. Retornar se necessário.",
    "status": "closed"
  }'
```

**Resposta (201 Created):**
```json
{
  "status": "success",
  "message": "Prontuário criado com sucesso",
  "medical_record": {
    "id": "692fc9999567890abcdef88",
    "patient_id": "692f9a1234567890abcdef12",
    "record_type": "discharge",
    "date": "2025-12-15",
    "time": "10:00",
    "chief_complaint": "Alta por melhora completa",
    "status": "closed"
  }
}
```

---

## 📊 Resumo do Fluxo Completo

```
1. Criar agenda com horários disponíveis
   ↓
2. Criar paciente com dados completos
   ↓
3. Criar consulta (consome slot da agenda automaticamente)
   ↓
4. Atualizar consulta (definir preço, confirmar)
   ↓
5. Consulta acontece
   ↓
6. Profissional cria prontuário - ANAMNESE (primeira consulta)
   ↓
7. Consultas de retorno: Profissional atualiza prontuário - EVOLUÇÃO
   ↓
8. Visualizar histórico completo (consultas + prontuários)
   ↓
9. Fim do tratamento: Profissional cria prontuário - ALTA
```

---

## 🔑 Tipos de Prontuário

- **anamnesis** - Primeira consulta, avaliação inicial
- **evolution** - Consultas de acompanhamento, evolução do tratamento  
- **discharge** - Alta médica, encerramento do tratamento

---

## 📌 Notas Importantes

1. **Gender** aceita: `"male"`, `"female"`, `"other"`
2. **Blood Type** aceita: `"A+"`, `"A-"`, `"B+"`, `"B-"`, `"AB+"`, `"AB-"`, `"O+"`, `"O-"`
3. **Datas** sempre no formato: `"YYYY-MM-DD"`
4. **Horários** sempre no formato: `"HH:MM"`
5. **appointment_date** no formato ISO: `"YYYY-MM-DDTHH:MM:SS-03:00"`
6. **Pain Scale** (escala de dor): 0 a 10
7. **Ao criar consulta**, o horário é **consumido automaticamente** da agenda

---

## 🎯 Ordem Recomendada para Implementar no Front

1. **Gestão de Agendas** → Criar slots disponíveis
2. **Gestão de Pacientes** → CRUD completo
3. **Gestão de Consultas** → Criar e atualizar
4. **Prontuário Médico** → Anamnese, evolução e alta

---

**Fluxo completo - Visão Empresa!** ✅
