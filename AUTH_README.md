# Sistema de Autenticação - API Fisio Back

## 🔐 Instalação

Primeiro, instale as novas dependências:

```bash
bundle install
```

## 📝 Variável de Ambiente

Adicione no seu arquivo `.env`:

```
JWT_SECRET=sua_chave_secreta_super_segura_aqui
```

## 🚀 Como Usar

### 1. Registrar um Novo Usuário

**Endpoint:** `POST /api/auth/register`

**Body:**
```json
{
  "name": "João Silva",
  "email": "joao@exemplo.com",
  "password": "senha123",
  "role": "user"
}
```

**Resposta:**
```json
{
  "status": "success",
  "message": "Usuário criado com sucesso",
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "...",
    "name": "João Silva",
    "email": "joao@exemplo.com",
    "role": "user"
  }
}
```

### 2. Fazer Login

**Endpoint:** `POST /api/auth/login`

**Body:**
```json
{
  "email": "joao@exemplo.com",
  "password": "senha123"
}
```

**Resposta:**
```json
{
  "status": "success",
  "message": "Login realizado com sucesso",
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "...",
    "name": "João Silva",
    "email": "joao@exemplo.com",
    "role": "user"
  }
}
```

### 3. Obter Dados do Usuário Atual

**Endpoint:** `GET /api/auth/me`

**Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**Resposta:**
```json
{
  "status": "success",
  "user": {
    "id": "...",
    "name": "João Silva",
    "email": "joao@exemplo.com",
    "role": "user"
  }
}
```

## 🔒 Rotas Protegidas

Agora as seguintes rotas requerem autenticação (enviar token no header Authorization):

- `POST /api/appointments` - Criar agendamento
- `GET /api/appointments` - Listar agendamentos
- `GET /api/appointments/:id` - Buscar agendamento
- `PATCH /api/appointments/:id` - Atualizar agendamento
- `DELETE /api/appointments/:id` - Deletar agendamento
- `POST /api/schedulings` - Criar agenda
- `GET /api/schedulings` - Listar agendas
- E todas as outras rotas da API

## 🌐 Rotas Públicas (não requerem autenticação)

- `GET /` - Status da API
- `GET /health` - Health check
- `POST /api/auth/register` - Registro
- `POST /api/auth/login` - Login

## 💡 Exemplo de Uso com cURL

```bash
# Registrar
curl -X POST http://localhost:9292/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"João Silva","email":"joao@exemplo.com","password":"senha123"}'

# Login
curl -X POST http://localhost:9292/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"joao@exemplo.com","password":"senha123"}'

# Usar token para acessar rota protegida
curl -X GET http://localhost:9292/api/appointments \
  -H "Authorization: Bearer SEU_TOKEN_AQUI"
```

## 🔑 Exemplo com JavaScript/Fetch

```javascript
// Login
const login = async () => {
  const response = await fetch('http://localhost:9292/api/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: 'joao@exemplo.com',
      password: 'senha123'
    })
  });
  
  const data = await response.json();
  
  // Salvar token (pode usar localStorage, sessionStorage, etc.)
  localStorage.setItem('token', data.token);
  
  return data;
};

// Fazer requisição autenticada
const getAppointments = async () => {
  const token = localStorage.getItem('token');
  
  const response = await fetch('http://localhost:9292/api/appointments', {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  return await response.json();
};
```

## 🛡️ Segurança

- Senhas são criptografadas com BCrypt
- Tokens JWT expiram em 24 horas
- Tokens devem ser enviados no header `Authorization: Bearer <token>`
- **IMPORTANTE:** Em produção, defina uma `JWT_SECRET` forte no arquivo `.env`

## 👤 Roles de Usuário

O sistema suporta diferentes roles:
- `user` - Usuário padrão
- `admin` - Administrador (pode ser usado para funcionalidades futuras)
