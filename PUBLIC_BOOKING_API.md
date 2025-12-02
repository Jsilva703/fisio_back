# 📅 API Pública de Agendamento Online

## 🌐 Rotas Públicas (SEM autenticação necessária)

Essas rotas são para a **tela pública de agendamento** onde os pacientes podem ver horários disponíveis e agendar consultas diretamente.

**Company ID da DJM Fisioterapia:** `692f1ffac90196fdf2a4fe2f`

---

## 1️⃣ **Ver Informações da Empresa**

```bash
curl -X GET http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/info
```

**Resposta:**
```json
{
  "status": "success",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia",
    "slug": "djm-fisioterapia",
    "email": "contato@djmfisio.com",
    "phone": "(11) 98888-7777",
    "address": "Rua das Flores, 123",
    "status": "active"
  }
}
```

---

## 2️⃣ **Listar Dias Disponíveis**

Ver todos os dias que têm horários disponíveis (a partir de hoje):

```bash
curl -X GET http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-days
```

**Resposta:**
```json
{
  "status": "success",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia",
    "slug": "djm-fisioterapia"
  },
  "available_days": [
    {
      "date": "2025-12-09",
      "slots": ["08:00", "09:00", "10:00", "14:00", "15:00"],
      "available_slots": 5
    },
    {
      "date": "2025-12-10",
      "slots": ["08:00", "09:00", "14:00", "15:00", "16:00"],
      "available_slots": 5
    }
  ]
}
```

---

## 3️⃣ **Ver Horários Disponíveis de um Dia Específico**

```bash
curl -X GET http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-slots/2025-12-09
```

**Resposta:**
```json
{
  "status": "success",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia"
  },
  "date": "2025-12-09",
  "available_slots": ["08:00", "09:00", "10:00", "14:00", "15:00"],
  "total_slots": 5
}
```

---

## 4️⃣ **Criar Agendamento (Paciente agenda online)**

```bash
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "João da Silva",
    "patient_phone": "11911031992",
    "patiente_document": "123.456.789-00",
    "type": "home",
    "duration": 60,
    "address": "Rua dos Testes, 100",
    "appointment_date": "2025-12-09T14:00:00-03:00",
    "price": 200.50
  }'
```

**Resposta de Sucesso:**
```json
{
  "status": "success",
  "message": "Agendamento realizado com sucesso!",
  "appointment": {
    "id": "674f1234567890abcdef1234",
    "patient_name": "João da Silva",
    "appointment_date": "2025-12-09T14:00:00-03:00",
    "type": "home",
    "address": "Rua dos Testes, 100",
    "price": 200.5
  }
}
```

**Resposta de Erro (horário já ocupado):**
```json
{
  "error": "Desculpe, o horário das 14:00 já não está disponível."
}
```

---

## 🎯 Fluxo de Uso no Frontend Público

### **Tela 1: Seleção de Dia**

```javascript
// Buscar dias disponíveis
const response = await fetch(
  'http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-days'
);
const data = await response.json();

// Mostrar calendário com dias disponíveis
data.available_days.forEach(day => {
  console.log(`${day.date}: ${day.available_slots} horários disponíveis`);
});
```

### **Tela 2: Seleção de Horário**

```javascript
// Usuário escolheu o dia 2025-12-09
const selectedDate = '2025-12-09';

const response = await fetch(
  `http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-slots/${selectedDate}`
);
const data = await response.json();

// Mostrar horários disponíveis
data.available_slots.forEach(slot => {
  console.log(`Horário: ${slot}`);
});
```

### **Tela 3: Formulário de Agendamento**

```javascript
// Usuário escolheu 14:00 e preencheu o formulário
const bookingData = {
  patient_name: "João da Silva",
  patient_phone: "11911031992",
  patiente_document: "123.456.789-00",
  type: "home", // ou "clinic"
  duration: 60,
  address: "Rua dos Testes, 100",
  appointment_date: "2025-12-09T14:00:00-03:00",
  price: 200.50
};

const response = await fetch(
  'http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book',
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(bookingData)
  }
);

const result = await response.json();

if (result.status === 'success') {
  alert('Agendamento realizado com sucesso!');
} else {
  alert(result.error);
}
```

---

## 🔒 Diferença entre Rotas Públicas e Privadas

### **Rotas Públicas** (sem token) - `/api/public/booking/:company_id`
- ✅ Ver dias disponíveis
- ✅ Ver horários disponíveis
- ✅ Fazer agendamento
- ❌ Não pode editar ou deletar agendamentos
- ❌ Não pode ver todos os agendamentos

### **Rotas Privadas** (com token) - `/api/appointments`
- ✅ Ver TODOS os agendamentos da empresa
- ✅ Editar agendamentos (status, pagamento)
- ✅ Deletar agendamentos
- ✅ Criar agendamentos (admin/user)

---

## 📋 Campos do Agendamento

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `patient_name` | String | ✅ Sim | Nome do paciente |
| `patient_phone` | String | ✅ Sim | Telefone do paciente |
| `patiente_document` | String | ❌ Não | CPF do paciente |
| `type` | String | ❌ Não | `clinic` ou `home` (padrão: clinic) |
| `duration` | Integer | ❌ Não | Duração em minutos (padrão: 60) |
| `address` | String | Condicional | Obrigatório se `type: "home"` |
| `appointment_date` | String | ✅ Sim | Data/hora no formato ISO 8601 |
| `price` | Float | ✅ Sim | Valor da consulta |

---

## 🚀 Como Integrar no Frontend

### **React/Next.js Example**

```jsx
// components/BookingCalendar.jsx
import { useState, useEffect } from 'react';

const COMPANY_ID = '692f1ffac90196fdf2a4fe2f';
const API_URL = 'http://localhost:9292/api/public/booking';

export default function BookingCalendar() {
  const [availableDays, setAvailableDays] = useState([]);
  const [selectedDate, setSelectedDate] = useState(null);
  const [availableSlots, setAvailableSlots] = useState([]);

  useEffect(() => {
    // Carregar dias disponíveis
    fetch(`${API_URL}/${COMPANY_ID}/available-days`)
      .then(res => res.json())
      .then(data => setAvailableDays(data.available_days));
  }, []);

  const handleDateSelect = async (date) => {
    setSelectedDate(date);
    
    // Carregar horários do dia selecionado
    const res = await fetch(`${API_URL}/${COMPANY_ID}/available-slots/${date}`);
    const data = await res.json();
    setAvailableSlots(data.available_slots);
  };

  const handleBooking = async (formData) => {
    const res = await fetch(`${API_URL}/${COMPANY_ID}/book`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData)
    });
    
    const result = await res.json();
    
    if (result.status === 'success') {
      alert('Agendamento realizado com sucesso!');
    } else {
      alert(result.error);
    }
  };

  return (
    <div>
      {/* Renderizar calendário e formulário */}
    </div>
  );
}
```

---

## ✅ Vantagens

1. **Sem autenticação** - Pacientes não precisam criar conta
2. **Verificação automática** - Sistema verifica disponibilidade em tempo real
3. **Consome vagas automaticamente** - Horário ocupado some da lista
4. **Multi-tenant** - Cada empresa tem sua própria agenda isolada

Seu sistema de agendamento online está pronto! 🎉
