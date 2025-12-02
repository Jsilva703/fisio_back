# 🤖 Sistema de Roles - Machine vs Admin/User

## 📋 Roles Disponíveis

- **`user`** - Usuário padrão da clínica
- **`admin`** - Administrador da clínica  
- **`machine`** - Sistema/máquina (SEM acesso a dados da clínica)

## 🔒 Regras de Acesso

### Role `machine`:
- ✅ Pode acessar: `/api/machine/*`
- ✅ Pode acessar: `/api/auth/me`
- ❌ **BLOQUEADO**: `/api/appointments/*`
- ❌ **BLOQUEADO**: `/api/schedulings/*`

### Roles `user` e `admin`:
- ✅ Acesso total a appointments e schedulings
- ❌ **BLOQUEADO**: `/api/machine/*` (exclusivo para machines)

## 🚀 Como Implementar no Frontend

### 1. No Login - Verificar o Role

```javascript
const login = async (email, password) => {
  const response = await fetch('http://localhost:9292/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  
  const data = await response.json();
  
  if (data.token) {
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
    
    // REDIRECIONAR BASEADO NO ROLE
    const role = data.user.role;
    
    if (role === 'machine') {
      // Redirecionar para dashboard da machine
      window.location.href = '/machine/dashboard';
    } else if (role === 'admin') {
      // Redirecionar para dashboard admin
      window.location.href = '/admin/dashboard';
    } else {
      // Redirecionar para dashboard user
      window.location.href = '/dashboard';
    }
  }
  
  return data;
};
```

### 2. Criar Rotas Protegidas por Role

```javascript
// App.jsx ou Routes.jsx
import { Navigate } from 'react-router-dom';

const ProtectedRoute = ({ children, allowedRoles }) => {
  const user = JSON.parse(localStorage.getItem('user'));
  
  if (!user) {
    return <Navigate to="/login" />;
  }
  
  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to="/unauthorized" />;
  }
  
  return children;
};

// Uso:
<Routes>
  <Route path="/login" element={<Login />} />
  
  {/* Rotas para MACHINE */}
  <Route path="/machine/*" element={
    <ProtectedRoute allowedRoles={['machine']}>
      <MachineLayout />
    </ProtectedRoute>
  } />
  
  {/* Rotas para ADMIN/USER */}
  <Route path="/admin/*" element={
    <ProtectedRoute allowedRoles={['admin', 'user']}>
      <AdminLayout />
    </ProtectedRoute>
  } />
  
  <Route path="/unauthorized" element={<Unauthorized />} />
</Routes>
```

### 3. Componente de Layout para Machine

```jsx
// MachineLayout.jsx
import { useEffect, useState } from 'react';

function MachineLayout() {
  const [dashboard, setDashboard] = useState(null);
  
  useEffect(() => {
    loadMachineDashboard();
  }, []);
  
  const loadMachineDashboard = async () => {
    const token = localStorage.getItem('token');
    
    const response = await fetch('http://localhost:9292/api/machine/dashboard', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    setDashboard(data);
  };
  
  return (
    <div className="machine-dashboard">
      <h1>🤖 Machine Dashboard</h1>
      <p>Status: {dashboard?.data?.status}</p>
      {/* Sua interface específica para machine aqui */}
      {/* SEM acesso a appointments/schedulings */}
    </div>
  );
}
```

### 4. Helper para Verificar Role

```javascript
// utils/auth.js
export const getCurrentUser = () => {
  const user = localStorage.getItem('user');
  return user ? JSON.parse(user) : null;
};

export const getUserRole = () => {
  const user = getCurrentUser();
  return user?.role || null;
};

export const isMachine = () => {
  return getUserRole() === 'machine';
};

export const isAdmin = () => {
  return getUserRole() === 'admin';
};

export const canAccessClinic = () => {
  const role = getUserRole();
  return role === 'admin' || role === 'user';
};

// Uso:
import { isMachine, canAccessClinic } from './utils/auth';

if (isMachine()) {
  // Mostrar interface de machine
} else if (canAccessClinic()) {
  // Mostrar interface de clínica
}
```

## 🧪 Testando com cURL

### 1. Criar usuário Machine
```bash
curl -X POST http://localhost:9292/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Machine System",
    "email": "machine@sistema.com",
    "password": "machine123",
    "role": "machine"
  }'
```

### 2. Login como Machine
```bash
MACHINE_TOKEN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"machine@sistema.com","password":"machine123"}' \
  | jq -r '.token')

echo "Token Machine: $MACHINE_TOKEN"
```

### 3. Tentar acessar appointments (DEVE SER BLOQUEADO)
```bash
curl -i -X GET http://localhost:9292/api/appointments \
  -H "Authorization: Bearer $MACHINE_TOKEN"

# Resposta esperada: 403 Forbidden
# {"error":"Acesso negado. Usuários do tipo machine não podem acessar dados da clínica."}
```

### 4. Acessar endpoint de machine (DEVE FUNCIONAR)
```bash
curl -X GET http://localhost:9292/api/machine/dashboard \
  -H "Authorization: Bearer $MACHINE_TOKEN"

# Resposta esperada: 200 OK com dados do dashboard
```

### 5. Criar usuário Admin
```bash
curl -X POST http://localhost:9292/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Admin",
    "email": "admin@clinica.com",
    "password": "admin123",
    "role": "admin"
  }'
```

### 6. Login como Admin e acessar appointments (DEVE FUNCIONAR)
```bash
ADMIN_TOKEN=$(curl -s -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@clinica.com","password":"admin123"}' \
  | jq -r '.token')

curl -X GET http://localhost:9292/api/appointments \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Deve funcionar normalmente
```

## 📊 Resumo da Estrutura

```
┌─────────────────────────────────────────┐
│           USUÁRIO FAZ LOGIN             │
└──────────────┬──────────────────────────┘
               │
               ▼
      ┌────────────────┐
      │  Verificar Role │
      └────────┬───────┘
               │
     ┌─────────┴──────────┐
     ▼                    ▼
┌─────────┐          ┌──────────┐
│ MACHINE │          │ADMIN/USER│
└────┬────┘          └─────┬────┘
     │                     │
     ▼                     ▼
/machine/dashboard   /admin/dashboard
     │                     │
     ▼                     ▼
Endpoints Machine    Appointments
/api/machine/*      Schedulings
                    /api/appointments/*
                    /api/schedulings/*
```

## 🎯 Fluxo Completo

1. **Frontend**: Usuário loga
2. **Backend**: Retorna token + user (com role)
3. **Frontend**: Salva token e role
4. **Frontend**: Redireciona baseado no role:
   - `machine` → Tela específica de machine
   - `admin/user` → Tela de clínica
5. **Frontend**: Usa o token em todas as requisições
6. **Backend**: Middleware valida:
   - Token válido? ✅
   - Role pode acessar essa rota? ✅
   - Se não → 403 Forbidden

## ⚠️ Importante

- No frontend, **SEMPRE** verificar o role após o login
- Nunca confiar apenas no frontend - o backend já valida
- Usuários `machine` **NÃO PODEM** acessar dados da clínica
- Você pode criar mais endpoints em `/api/machine/*` conforme necessário
