# 🔐 Exemplos de Uso da API com Autenticação

## 📱 Como Usar no Frontend

### 1. Fluxo Completo de Autenticação

```javascript
// ========================================
// 1. REGISTRO DE USUÁRIO
// ========================================
const register = async (userData) => {
  const response = await fetch('http://localhost:9292/api/auth/register', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      name: userData.name,
      email: userData.email,
      password: userData.password,
      role: 'user'
    })
  });
  
  const data = await response.json();
  
  if (data.token) {
    // Salvar token para usar nas próximas requisições
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
  }
  
  return data;
};

// ========================================
// 2. LOGIN
// ========================================
const login = async (email, password) => {
  const response = await fetch('http://localhost:9292/api/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password })
  });
  
  const data = await response.json();
  
  if (data.token) {
    // Salvar token
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
  }
  
  return data;
};

// ========================================
// 3. LOGOUT
// ========================================
const logout = () => {
  localStorage.removeItem('token');
  localStorage.removeItem('user');
  // Redirecionar para página de login
  window.location.href = '/login';
};

// ========================================
// 4. VERIFICAR SE ESTÁ AUTENTICADO
// ========================================
const isAuthenticated = () => {
  return !!localStorage.getItem('token');
};

// ========================================
// 5. PEGAR TOKEN SALVO
// ========================================
const getToken = () => {
  return localStorage.getItem('token');
};

// ========================================
// 6. FUNÇÃO HELPER PARA REQUISIÇÕES AUTENTICADAS
// ========================================
const fetchWithAuth = async (url, options = {}) => {
  const token = getToken();
  
  if (!token) {
    throw new Error('Usuário não autenticado');
  }
  
  const response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    }
  });
  
  // Se o token expirou ou é inválido, fazer logout
  if (response.status === 401) {
    logout();
    throw new Error('Sessão expirada. Faça login novamente.');
  }
  
  return response;
};

// ========================================
// 7. CRIAR AGENDAMENTO (COM TOKEN)
// ========================================
const createAppointment = async (appointmentData) => {
  const response = await fetchWithAuth('http://localhost:9292/api/appointments', {
    method: 'POST',
    body: JSON.stringify(appointmentData)
  });
  
  return await response.json();
};

// ========================================
// 8. LISTAR AGENDAMENTOS (COM TOKEN)
// ========================================
const getAppointments = async () => {
  const response = await fetchWithAuth('http://localhost:9292/api/appointments', {
    method: 'GET'
  });
  
  return await response.json();
};

// ========================================
// 9. BUSCAR AGENDAMENTO POR ID (COM TOKEN)
// ========================================
const getAppointmentById = async (id) => {
  const response = await fetchWithAuth(`http://localhost:9292/api/appointments/${id}`, {
    method: 'GET'
  });
  
  return await response.json();
};

// ========================================
// 10. ATUALIZAR AGENDAMENTO (COM TOKEN)
// ========================================
const updateAppointment = async (id, updates) => {
  const response = await fetchWithAuth(`http://localhost:9292/api/appointments/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(updates)
  });
  
  return await response.json();
};

// ========================================
// 11. DELETAR AGENDAMENTO (COM TOKEN)
// ========================================
const deleteAppointment = async (id) => {
  const response = await fetchWithAuth(`http://localhost:9292/api/appointments/${id}`, {
    method: 'DELETE'
  });
  
  return await response.json();
};

// ========================================
// 12. CRIAR AGENDA DE HORÁRIOS (COM TOKEN)
// ========================================
const createScheduling = async (schedulingData) => {
  const response = await fetchWithAuth('http://localhost:9292/api/schedulings', {
    method: 'POST',
    body: JSON.stringify(schedulingData)
  });
  
  return await response.json();
};

// ========================================
// 13. LISTAR AGENDAS (COM TOKEN)
// ========================================
const getSchedulings = async () => {
  const response = await fetchWithAuth('http://localhost:9292/api/schedulings', {
    method: 'GET'
  });
  
  return await response.json();
};
```

## 🔥 Exemplo de Uso em um Componente React

```jsx
import { useState, useEffect } from 'react';

function AppointmentsPage() {
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadAppointments();
  }, []);

  const loadAppointments = async () => {
    try {
      setLoading(true);
      const data = await getAppointments();
      setAppointments(data.agendamentos || []);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateAppointment = async (formData) => {
    try {
      await createAppointment({
        patient_name: formData.name,
        patient_phone: formData.phone,
        patiente_document: formData.document,
        type: formData.type,
        address: formData.address,
        appointment_date: formData.date,
        price: formData.price
      });
      
      // Recarregar lista
      loadAppointments();
      alert('Agendamento criado com sucesso!');
    } catch (err) {
      alert('Erro ao criar agendamento: ' + err.message);
    }
  };

  if (loading) return <div>Carregando...</div>;
  if (error) return <div>Erro: {error}</div>;

  return (
    <div>
      <h1>Meus Agendamentos</h1>
      {appointments.map(apt => (
        <div key={apt._id}>
          <p>{apt.patient_name} - {apt.appointment_date}</p>
        </div>
      ))}
    </div>
  );
}
```

## 🧪 Exemplos com cURL

```bash
# ========================================
# 1. FAZER LOGIN E SALVAR TOKEN
# ========================================
TOKEN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@fisio.com","password":"admin123"}' \
  | jq -r '.token')

echo "Token: $TOKEN"

# ========================================
# 2. LISTAR AGENDAMENTOS COM TOKEN
# ========================================
curl -X GET http://localhost:9292/api/appointments \
  -H "Authorization: Bearer $TOKEN"

# ========================================
# 3. CRIAR AGENDAMENTO COM TOKEN
# ========================================
curl -X POST http://localhost:9292/api/appointments \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_name": "João Silva",
    "patient_phone": "(11) 98888-7777",
    "patiente_document": "123.456.789-00",
    "type": "clinic",
    "appointment_date": "2025-12-10T14:00:00-03:00",
    "price": 150.0
  }'

# ========================================
# 4. ATUALIZAR AGENDAMENTO COM TOKEN
# ========================================
curl -X PATCH http://localhost:9292/api/appointments/ID_DO_AGENDAMENTO \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "confirmed",
    "paid": true
  }'

# ========================================
# 5. DELETAR AGENDAMENTO COM TOKEN
# ========================================
curl -X DELETE http://localhost:9292/api/appointments/ID_DO_AGENDAMENTO \
  -H "Authorization: Bearer $TOKEN"

# ========================================
# 6. CRIAR AGENDA COM TOKEN
# ========================================
curl -X POST http://localhost:9292/api/schedulings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "date": "2025-12-10",
    "slots": ["08:00", "09:00", "10:00", "14:00", "15:00", "16:00"]
  }'
```

## 🚨 Tratamento de Erros

```javascript
const handleApiRequest = async (apiFunction) => {
  try {
    const result = await apiFunction();
    return { success: true, data: result };
  } catch (error) {
    if (error.message === 'Sessão expirada. Faça login novamente.') {
      // Token expirado - redirecionar para login
      alert('Sua sessão expirou. Faça login novamente.');
      window.location.href = '/login';
    } else {
      // Outro erro
      return { success: false, error: error.message };
    }
  }
};

// Uso:
const result = await handleApiRequest(() => getAppointments());
if (result.success) {
  console.log('Agendamentos:', result.data);
} else {
  console.error('Erro:', result.error);
}
```

## 🔒 Verificação de Autenticação em Rotas

```javascript
// Exemplo de proteção de rota no frontend
const ProtectedRoute = ({ children }) => {
  if (!isAuthenticated()) {
    window.location.href = '/login';
    return null;
  }
  
  return children;
};

// Uso em um router
<Route path="/agendamentos">
  <ProtectedRoute>
    <AppointmentsPage />
  </ProtectedRoute>
</Route>
```

## 📊 Resumo das Rotas

| Rota | Método | Requer Token? | Descrição |
|------|--------|---------------|-----------|
| `/` | GET | ❌ Não | Status da API |
| `/health` | GET | ❌ Não | Health check |
| `/api/auth/register` | POST | ❌ Não | Registrar usuário |
| `/api/auth/login` | POST | ❌ Não | Login |
| `/api/auth/me` | GET | ✅ Sim | Dados do usuário atual |
| `/api/appointments` | POST | ✅ Sim | Criar agendamento |
| `/api/appointments` | GET | ✅ Sim | Listar agendamentos |
| `/api/appointments/:id` | GET | ✅ Sim | Buscar agendamento |
| `/api/appointments/:id` | PATCH | ✅ Sim | Atualizar agendamento |
| `/api/appointments/:id` | DELETE | ✅ Sim | Deletar agendamento |
| `/api/schedulings` | POST | ✅ Sim | Criar agenda |
| `/api/schedulings` | GET | ✅ Sim | Listar agendas |

## ⚠️ Erros Comuns

**401 - Token não fornecido**
```json
{ "error": "Token não fornecido" }
```
→ Você esqueceu de enviar o header `Authorization`

**401 - Token inválido**
```json
{ "error": "Token inválido" }
```
→ O token está malformado ou incorreto

**401 - Token expirado**
```json
{ "error": "Token expirado" }
```
→ O token expirou (24h), faça login novamente
