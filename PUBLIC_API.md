# 🌐 APIs Públicas - PhysioCore

## Visão Geral

APIs públicas para que pacientes possam interagir com a clínica **SEM AUTENTICAÇÃO**.
Todas as rotas usam o **company_id** na URL.

## Base URL
```
/api/public/booking
```

**⚠️ IMPORTANTE**: Essas rotas **NÃO REQUEREM** token de autenticação.

---

## 📋 Endpoints Disponíveis

### 1. Informações da Clínica
**GET** `/api/public/booking/:company_id/info`

Retorna informações públicas da clínica.

**Exemplo:**
```bash
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/info
```

**Response 200:**
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

### 2. Listar Dias Disponíveis
**GET** `/api/public/booking/:company_id/available-days`

Lista todos os dias com horários disponíveis para agendamento.

**Exemplo:**
```bash
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-days
```

**Response 200:**
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
      "date": "2025-12-03",
      "slots": ["09:00", "10:00", "14:00", "15:00"],
      "available_slots": 4
    },
    {
      "date": "2025-12-04",
      "slots": ["09:00", "11:00", "14:00"],
      "available_slots": 3
    }
  ]
}
```

---

### 3. Buscar Horários de um Dia Específico
**GET** `/api/public/booking/:company_id/available-slots/:date`

Retorna os horários disponíveis de uma data específica.

**Parâmetros:**
- `:company_id` - ID da empresa
- `:date` - Data no formato YYYY-MM-DD

**Exemplo:**
```bash
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-slots/2025-12-05
```

**Response 200:**
```json
{
  "status": "success",
  "company": {
    "id": "692f1ffac90196fdf2a4fe2f",
    "name": "DJM Fisioterapia"
  },
  "date": "2025-12-05",
  "available_slots": ["09:00", "10:00", "11:00", "14:00", "15:00", "16:00"],
  "total_slots": 6
}
```

**Response 404 (sem horários):**
```json
{
  "error": "Nenhum horário disponível para esta data",
  "date": "2025-12-05"
}
```

---

### 4. Cadastrar Paciente (Público)
**POST** `/api/public/booking/:company_id/register-patient`

Permite que um paciente se cadastre na clínica pela internet.

**Request Body:**
```json
{
  "name": "Maria Santos",
  "phone": "(11) 99999-8888",
  "email": "maria@email.com",
  "cpf": "987.654.321-00",
  "birth_date": "1990-03-20",
  "gender": "female",
  "address": {
    "street": "Rua Exemplo",
    "number": "456",
    "city": "São Paulo",
    "state": "SP"
  },
  "notes": "Encaminhado pelo ortopedista"
}
```

**Campos Obrigatórios:**
- `name` (String)
- `phone` (String)

**Campos Opcionais:**
- `email` (String)
- `cpf` (String)
- `birth_date` (String, YYYY-MM-DD)
- `gender` (String): `male` | `female` | `other`
- `address` (Hash)
- `notes` (String)

**Exemplo:**
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

**Response 409 (CPF já existe):**
```json
{
  "error": "CPF já cadastrado",
  "patient_id": "692f5a2df9186f4757bc4680"
}
```

---

### 5. Agendar Consulta (Com Auto-Cadastro)
**POST** `/api/public/booking/:company_id/book-appointment`

Permite que um paciente agende uma consulta. Se o paciente não existir, será criado automaticamente.

**Request Body:**
```json
{
  "patient_name": "João Silva",
  "patient_phone": "(11) 98765-4321",
  "patient_email": "joao@email.com",
  "patient_cpf": "123.456.789-00",
  "appointment_date": "2025-12-05T09:00:00",
  "procedure": "Fisioterapia",
  "type": "clinic",
  "price": 150.00,
  "duration": 60
}
```

**Campos Obrigatórios:**
- `patient_name` (String)
- `patient_phone` (String)
- `appointment_date` (String, formato: YYYY-MM-DDTHH:MM:SS)

**Campos Opcionais:**
- `patient_email` (String)
- `patient_cpf` (String)
- `procedure` (String, padrão: "Consulta")
- `type` (String): `clinic` | `home` (padrão: "clinic")
- `address` (String, obrigatório se type=home)
- `price` (Float, padrão: 0)
- `duration` (Integer, padrão: 60 minutos)

**Exemplo:**
```bash
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book-appointment \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "João Silva",
    "patient_phone": "(11) 98765-4321",
    "patient_email": "joao@email.com",
    "patient_cpf": "123.456.789-00",
    "appointment_date": "2025-12-05T09:00:00",
    "procedure": "Fisioterapia Ortopédica",
    "type": "clinic",
    "price": 150.00
  }'
```

**Response 201:**
```json
{
  "status": "success",
  "message": "Agendamento realizado com sucesso!",
  "appointment": {
    "id": "692f5b1af9186f4757bc4681",
    "patient_name": "João Silva",
    "patient_phone": "(11) 98765-4321",
    "date": "2025-12-05",
    "time": "09:00",
    "procedure": "Fisioterapia Ortopédica",
    "type": "clinic",
    "address": null,
    "price": 150.0
  },
  "patient": {
    "id": "692f582df9186f4757bc467d",
    "name": "João Silva",
    "is_new": false
  }
}
```

**Response 409 (horário indisponível):**
```json
{
  "error": "Horário 09:00 não disponível para 2025-12-05"
}
```

**Response 403 (empresa suspensa):**
```json
{
  "error": "Clínica temporariamente indisponível"
}
```

---

### 6. Agendamento Simples (Legado)
**POST** `/api/public/booking/:company_id/book`

Versão legada do agendamento (mantida para compatibilidade).

**Request Body:**
```json
{
  "patient_name": "João Silva",
  "patient_phone": "(11) 98765-4321",
  "patiente_document": "123.456.789-00",
  "appointment_date": "2025-12-05T09:00:00",
  "type": "clinic",
  "address": "",
  "price": 150.00,
  "duration": 60
}
```

**⚠️ Nota**: Esta rota **NÃO** cria paciente automaticamente, apenas o agendamento.

---

## 🔄 Fluxo Completo de Agendamento

### Cenário 1: Paciente Novo

```bash
# 1. Ver informações da clínica
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/info

# 2. Ver dias disponíveis
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-days

# 3. Ver horários de um dia específico
curl http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/available-slots/2025-12-05

# 4. Fazer cadastro + agendamento em uma única chamada
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book-appointment \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "Maria Santos",
    "patient_phone": "(11) 99999-8888",
    "patient_email": "maria@email.com",
    "patient_cpf": "987.654.321-00",
    "appointment_date": "2025-12-05T09:00:00",
    "procedure": "Fisioterapia",
    "price": 150.00
  }'
```

### Cenário 2: Paciente Existente

```bash
# Sistema reconhece automaticamente pelo CPF ou telefone
curl -X POST http://localhost:9292/api/public/booking/692f1ffac90196fdf2a4fe2f/book-appointment \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "João Silva",
    "patient_phone": "(11) 98765-4321",
    "appointment_date": "2025-12-05T14:00:00",
    "procedure": "Retorno"
  }'
```

---

## 🎯 Validações e Regras

### Disponibilidade de Horários
- ✅ Só mostra horários futuros (a partir de hoje)
- ✅ Horários consumidos são removidos automaticamente
- ✅ Empresas suspensas não permitem agendamento

### Auto-Cadastro de Pacientes
- Se **CPF** informado: busca paciente existente por CPF
- Se não encontrar por CPF: busca por **telefone**
- Se não encontrar: **cria novo paciente** automaticamente
- Campo `source` = `"online_booking"` para pacientes criados pela API pública

### Status da Empresa
- `active`: Permite agendamentos ✅
- `inactive`: Bloqueia agendamentos ❌
- `suspended`: Bloqueia agendamentos ❌

### Pagamentos
- Agendamentos públicos sempre criam com `payment_status: "pending"`
- Agendamentos públicos sempre criam com `status: "scheduled"`

---

## 🚨 Tratamento de Erros

### 404 - Not Found
```json
{
  "error": "Empresa não encontrada"
}
```

### 403 - Forbidden
```json
{
  "error": "Empresa inativa ou suspensa"
}
```

### 409 - Conflict
```json
{
  "error": "Horário 09:00 não disponível para 2025-12-05"
}
```

### 400 - Bad Request
```json
{
  "error": "Campos obrigatórios faltando: patient_name, patient_phone"
}
```

### 422 - Unprocessable Entity
```json
{
  "error": "Erro ao criar agendamento",
  "details": {
    "patient_phone": ["can't be blank"]
  }
}
```

---

## 💡 Exemplos Práticos

### Widget de Agendamento (HTML + JS)

```html
<!DOCTYPE html>
<html>
<head>
  <title>Agendar Consulta - DJM Fisioterapia</title>
</head>
<body>
  <h1>Agende sua Consulta</h1>
  
  <form id="bookingForm">
    <input type="text" id="name" placeholder="Nome completo" required>
    <input type="tel" id="phone" placeholder="Telefone" required>
    <input type="email" id="email" placeholder="E-mail">
    <input type="text" id="cpf" placeholder="CPF">
    <input type="date" id="date" required>
    <select id="time" required></select>
    <button type="submit">Agendar</button>
  </form>

  <script>
    const COMPANY_ID = '692f1ffac90196fdf2a4fe2f';
    const API_BASE = 'http://localhost:9292/api/public/booking';

    // Carregar horários disponíveis quando escolher data
    document.getElementById('date').addEventListener('change', async (e) => {
      const date = e.target.value;
      const response = await fetch(`${API_BASE}/${COMPANY_ID}/available-slots/${date}`);
      const data = await response.json();
      
      const timeSelect = document.getElementById('time');
      timeSelect.innerHTML = '';
      
      if (data.available_slots) {
        data.available_slots.forEach(slot => {
          const option = document.createElement('option');
          option.value = slot;
          option.textContent = slot;
          timeSelect.appendChild(option);
        });
      }
    });

    // Enviar agendamento
    document.getElementById('bookingForm').addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const appointmentDate = document.getElementById('date').value + 'T' + document.getElementById('time').value + ':00';
      
      const data = {
        patient_name: document.getElementById('name').value,
        patient_phone: document.getElementById('phone').value,
        patient_email: document.getElementById('email').value,
        patient_cpf: document.getElementById('cpf').value,
        appointment_date: appointmentDate,
        procedure: 'Fisioterapia',
        price: 150.00
      };

      const response = await fetch(`${API_BASE}/${COMPANY_ID}/book-appointment`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });

      const result = await response.json();
      
      if (response.ok) {
        alert('Agendamento realizado com sucesso!');
      } else {
        alert('Erro: ' + result.error);
      }
    });
  </script>
</body>
</html>
```

---

## 🔗 Links Úteis

- [Documentação Completa de Pacientes](./PATIENTS_API.md)
- [Documentação de Billing](./BILLING_GUIDE.md)
- [Documentação de Empresas](./COMPANIES_API.md)

---

## 📌 Notas Importantes

1. **Sem Autenticação**: Todas essas rotas são públicas e não requerem token
2. **Rate Limiting**: Recomenda-se implementar rate limiting em produção
3. **CORS**: Configurar CORS para domínios específicos em produção
4. **Validação de Dados**: Frontend deve validar dados antes de enviar
5. **Confirmação**: Enviar email/SMS de confirmação após agendamento (implementar)
6. **Cancelamento**: Implementar rota pública para cancelamento com token único

---

## 🚀 Próximas Melhorias

- [ ] Rota para cancelamento público (via token único)
- [ ] Rota para reagendamento
- [ ] Integração com Google Calendar
- [ ] Notificações por WhatsApp/SMS
- [ ] Lembretes automáticos
- [ ] Avaliação pós-consulta
