# 🚀 CURLs - APIs Públicas do PhysioCore

## 📌 Informações
- **Company ID**: `692f1ffac90196fdf2a4fe2f` (DJM Fisioterapia)
- **Base URL**: `http://localhost:9292/api/public/booking`
- **Autenticação**: ❌ Não requer token (APIs públicas)

---

## 1️⃣ Buscar Informações da Clínica

```bash
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/info
```

**Response esperado:**
```json
{
  "status": "success",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia",
    "slug": "djm-fisioterapia",
    "email": "contato@djmfisio.com",
    "phone": "(11) 91234-5678",
    "address": "Av. Paulista, 1000 - São Paulo",
    "status": "active"
  }
}
```

---

## 2️⃣ Listar Dias Disponíveis

```bash
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-days
```

---

## 3️⃣ Buscar Horários de um Dia Específico

```bash
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-slots/2025-12-05
```

---

## 4️⃣ ⭐ VERIFICAR SE PACIENTE EXISTE (NOVO!)

### Por CPF:
```bash
curl "http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/check-patient?cpf=123.456.789-00"
```

### Por Telefone:
```bash
curl "http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/check-patient?phone=(11)98765-4321"
```

### Por CPF e Telefone (busca primeiro por CPF):
```bash
curl "http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/check-patient?cpf=123.456.789-00&phone=(11)98765-4321"
```

**Response quando ENCONTRA:**
```json
{
  "status": "success",
  "patient_exists": true,
  "patient": {
    "id": "692f582df9186f4757bc467d",
    "name": "João Silva",
    "email": "joao@email.com",
    "phone": "(11) 98765-4321",
    "cpf": "123.456.789-00",
    "birth_date": "1985-05-15",
    "total_appointments": 0,
    "last_appointment": null
  }
}
```

**Response quando NÃO ENCONTRA:**
```json
{
  "status": "success",
  "patient_exists": false,
  "message": "Paciente não encontrado. Você pode se cadastrar."
}
```

---

## 5️⃣ Cadastrar Novo Paciente

```bash
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/register-patient \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Maria Santos",
    "phone": "(11) 99999-8888",
    "email": "maria@email.com",
    "cpf": "987.654.321-00",
    "birth_date": "1990-03-20",
    "gender": "female"
  }'
```

**Response 201:**
```json
{
  "status": "success",
  "message": "Cadastro realizado com sucesso!",
  "patient": {
    "id": "692f5a2df9186f4757bc4680",
    "name": "Maria Santos",
    "email": "maria@email.com",
    "phone": "(11) 99999-8888"
  }
}
```

---

## 6️⃣ Agendar Consulta (Com Auto-Cadastro)

### Paciente Novo:
```bash
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book-appointment \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "Pedro Costa",
    "patient_phone": "(11) 97777-6666",
    "patient_email": "pedro@email.com",
    "patient_cpf": "111.222.333-44",
    "appointment_date": "2025-12-05T09:00:00",
    "procedure": "Fisioterapia Ortopédica",
    "type": "clinic",
    "price": 150.00
  }'
```

### Paciente Existente (reconhece por CPF ou telefone):
```bash
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book-appointment \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "João Silva",
    "patient_phone": "(11) 98765-4321",
    "patient_cpf": "123.456.789-00",
    "appointment_date": "2025-12-05T14:00:00",
    "procedure": "Retorno"
  }'
```

**Response 201:**
```json
{
  "status": "success",
  "message": "Agendamento realizado com sucesso!",
  "appointment": {
    "id": "692f5b1af9186f4757bc4681",
    "patient_name": "Pedro Costa",
    "patient_phone": "(11) 97777-6666",
    "date": "2025-12-05",
    "time": "09:00",
    "procedure": "Fisioterapia Ortopédica",
    "type": "clinic",
    "address": null,
    "price": 150.0
  },
  "patient": {
    "id": "692f5a2df9186f4757bc4680",
    "name": "Pedro Costa",
    "is_new": true
  }
}
```

---

## 🔄 Fluxo Completo no Frontend

### 1. Usuário preenche CPF
```bash
curl "http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/check-patient?cpf=123.456.789-00"
```

**Se `patient_exists: true`:**
- ✅ Preenche nome e telefone automaticamente
- ✅ Pula para seleção de data/hora
- ✅ Chama `/book-appointment` direto

**Se `patient_exists: false`:**
- ✅ Mostra formulário completo de cadastro
- ✅ Após preencher, chama `/book-appointment`
- ✅ Sistema cria paciente automaticamente

### 2. Ver dias disponíveis
```bash
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-days
```

### 3. Selecionar dia e ver horários
```bash
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-slots/2025-12-05
```

### 4. Confirmar agendamento
```bash
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book-appointment \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "João Silva",
    "patient_phone": "(11) 98765-4321",
    "patient_cpf": "123.456.789-00",
    "appointment_date": "2025-12-05T09:00:00",
    "procedure": "Fisioterapia"
  }'
```

---

## 🧪 Testes Rápidos

### Teste 1: Verificar se paciente existe
```bash
# Buscar por CPF existente
curl "http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/check-patient?cpf=123.456.789-00"

# Buscar por CPF inexistente
curl "http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/check-patient?cpf=999.999.999-99"
```

### Teste 2: Cadastrar + Agendar em sequência
```bash
# 1. Verificar se existe
curl "http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/check-patient?cpf=555.666.777-88"

# 2. Se não existir, fazer agendamento (cria automaticamente)
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book-appointment \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "Ana Paula",
    "patient_phone": "(11) 96666-5555",
    "patient_cpf": "555.666.777-88",
    "appointment_date": "2025-12-05T10:00:00",
    "procedure": "Fisioterapia"
  }'
```

---

## 📱 Exemplo de Integração Frontend (JavaScript)

```javascript
const COMPANY_ID = '692f1ffac90196fdf2a4fe2f';
const API_BASE = 'http://localhost:9292/api/public/booking';

// 1. Verificar se paciente existe ao digitar CPF
async function checkPatient(cpf) {
  const response = await fetch(`${API_BASE}/${COMPANY_ID}/check-patient?cpf=${cpf}`);
  const data = await response.json();
  
  if (data.patient_exists) {
    // Preenche campos automaticamente
    document.getElementById('name').value = data.patient.name;
    document.getElementById('phone').value = data.patient.phone;
    document.getElementById('email').value = data.patient.email;
    
    // Mostra mensagem
    alert(`Olá ${data.patient.name}! Encontramos seu cadastro.`);
    
    // Pula para seleção de horário
    showDateSelection();
  } else {
    // Mostra formulário completo
    alert('Não encontramos seu cadastro. Por favor, preencha seus dados.');
    showFullForm();
  }
}

// 2. Buscar horários disponíveis
async function loadAvailableSlots(date) {
  const response = await fetch(`${API_BASE}/${COMPANY_ID}/available-slots/${date}`);
  const data = await response.json();
  
  if (data.available_slots) {
    // Popula select de horários
    const select = document.getElementById('time');
    data.available_slots.forEach(slot => {
      const option = document.createElement('option');
      option.value = slot;
      option.textContent = slot;
      select.appendChild(option);
    });
  }
}

// 3. Fazer agendamento
async function bookAppointment(formData) {
  const response = await fetch(`${API_BASE}/${COMPANY_ID}/book-appointment`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(formData)
  });
  
  const data = await response.json();
  
  if (response.ok) {
    alert(`Agendamento confirmado para ${data.appointment.date} às ${data.appointment.time}!`);
    if (data.patient.is_new) {
      alert('Seu cadastro foi criado com sucesso!');
    }
  } else {
    alert('Erro: ' + data.error);
  }
}
```

---

## ⚙️ Variáveis de Ambiente

Para facilitar os testes, defina:

```bash
export COMPANY_ID="692f1ffac90196fdf2a4fe2f"
export API_BASE="http://localhost:9292/api/public/booking"

# Agora pode usar assim:
curl "$API_BASE/$COMPANY_ID/info"
curl "$API_BASE/$COMPANY_ID/check-patient?cpf=123.456.789-00"
```

---

## 🎯 Resumo das APIs

| Endpoint | Método | Autenticação | Descrição |
|----------|--------|--------------|-----------|
| `/:company_id/info` | GET | ❌ Não | Informações da clínica |
| `/:company_id/available-days` | GET | ❌ Não | Dias com horários disponíveis |
| `/:company_id/available-slots/:date` | GET | ❌ Não | Horários de um dia específico |
| `/:company_id/check-patient` | GET | ❌ Não | **NOVO!** Verifica se paciente existe |
| `/:company_id/register-patient` | POST | ❌ Não | Cadastrar novo paciente |
| `/:company_id/book-appointment` | POST | ❌ Não | Agendar (com auto-cadastro) |

---

## 🚀 Pronto para Produção!

Todas as APIs estão funcionando e prontas para integração no frontend! 🎉
