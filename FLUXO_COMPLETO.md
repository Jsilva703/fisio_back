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

**⚠️ Todas as APIs abaixo exigem:**
```
Authorization: Bearer SEU_TOKEN_EMPRESA
```

### 5. Listar consultas agendadas

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
      "procedure": "Fisioterapia",
      "appointment_date": "2025-12-05T10:00:00-03:00",
      "duration": 60,
      "price": 0,
      "status": "scheduled",
      "payment_status": "pending",
      "created_at": "2025-12-04T14:30:00-03:00"
    }
  ]
}
```

---

### 6. Atualizar consulta (definir preço)

```bash
curl -X PATCH "http://localhost:9292/api/appointments/692fab9876543210fedcba98" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "price": 150.00,
    "status": "confirmed"
  }'
```

**Resposta:**
```json
{
  "status": "success",
  "agendamento": {
    "id": "692fab9876543210fedcba98",
    "patient_name": "Maria Santos",
    "price": 150.0,
    "status": "confirmed",
    "payment_status": "pending"
  }
}
```

---

### 7. Listar pacientes da empresa

```bash
curl -X GET "http://localhost:9292/api/patients?page=1&per_page=20" \
  -H "Authorization: Bearer eyJhbGc..."
```

**Resposta:**
```json
{
  "status": "success",
  "total": 2,
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
      "birth_date": null,
      "age": null,
      "gender": null,
      "blood_type": null,
      "status": "active",
      "source": "online_booking",
      "total_appointments": 1,
      "last_appointment": "2025-12-05",
      "created_at": "2025-12-04T14:30:00-03:00"
    }
  ]
}
```

---

### 8. Ver detalhes do paciente

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
    "rg": null,
    "birth_date": null,
    "age": null,
    "gender": null,
    "address": {},
    "blood_type": null,
    "allergies": [],
    "medications": [],
    "health_insurance": {},
    "emergency_contact": {},
    "status": "active",
    "notes": null,
    "source": "online_booking",
    "total_appointments": 1,
    "last_appointment": "2025-12-05",
    "created_at": "2025-12-04T14:30:00-03:00",
    "updated_at": "2025-12-04T14:30:00-03:00"
  }
}
```

---

### 9. Atualizar dados do paciente

```bash
curl -X PUT "http://localhost:9292/api/patients/692f9a1234567890abcdef12" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "birth_date": "1990-05-20",
    "gender": "female",
    "blood_type": "O+",
    "address": {
      "street": "Rua das Flores",
      "number": "123",
      "city": "São Paulo",
      "state": "SP",
      "zip_code": "01234-567"
    },
    "allergies": ["Dipirona"],
    "emergency_contact": {
      "name": "José Santos",
      "relationship": "Esposo",
      "phone": "(11) 98888-7777"
    }
  }'
```

**Resposta:**
```json
{
  "status": "success",
  "message": "Paciente atualizado com sucesso",
  "patient": {
    "id": "692f9a1234567890abcdef12",
    "name": "Maria Santos",
    "email": "maria@email.com",
    "phone": "(11) 91234-5678",
    "age": 34,
    "gender": "female",
    "blood_type": "O+"
  }
}
```

---

## 📋 FASE 3: Prontuário Médico

### 10. Criar prontuário (anamnese)

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
    "chief_complaint": "Dor lombar há 3 semanas"
  }
}
```

---

### 11. Atualizar prontuário (evolução)

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

### 12. Ver histórico completo do paciente

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
      "procedure": "Fisioterapia",
      "price": 150.0,
      "payment_status": "pending"
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

### 13. Criar prontuário de alta

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
    "chief_complaint": "Alta por melhora completa"
  }
}
```

---

## 📊 Resumo do Fluxo Completo

```
1. Cliente vê dias disponíveis (público)
   ↓
2. Cliente vê horários do dia (público)
   ↓
3. Sistema verifica se cliente existe por CPF (público)
   ↓
4. Se não existe: Cadastra paciente (público)
   ↓
5. Cliente agenda consulta (público - auto-cadastro se necessário)
   ↓
6. Recepcionista vê consultas agendadas (autenticado)
   ↓
7. Recepcionista define preço da consulta (autenticado)
   ↓
8. Recepcionista completa dados do paciente (autenticado)
   ↓
9. Consulta acontece
   ↓
10. Profissional cria prontuário - anamnese (autenticado)
    ↓
11. Consultas de retorno: Profissional atualiza prontuário - evolução (autenticado)
    ↓
12. Visualizar histórico completo do paciente (autenticado)
    ↓
13. Fim do tratamento: Profissional cria prontuário de alta (autenticado)
```

---

## 🔑 Tipos de Prontuário

- **anamnesis** - Primeira consulta, avaliação inicial
- **evolution** - Consultas de acompanhamento, evolução do tratamento
- **discharge** - Alta médica, encerramento do tratamento

---

## 📌 Notas Importantes

1. **APIs Públicas** não precisam de autenticação
2. **APIs Internas** exigem token JWT no header `Authorization: Bearer TOKEN`
3. **Gender** aceita: `"male"`, `"female"`, `"other"`
4. **Blood Type** aceita: `"A+"`, `"A-"`, `"B+"`, `"B-"`, `"AB+"`, `"AB-"`, `"O+"`, `"O-"`
5. **Datas** sempre no formato: `"YYYY-MM-DD"`
6. **Horários** sempre no formato: `"HH:MM"`
7. **Pain Scale** (escala de dor): 0 a 10

---

**Fluxo completo testado e funcional!** ✅
