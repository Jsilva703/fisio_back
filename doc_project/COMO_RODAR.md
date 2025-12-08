# 🚀 Como Rodar o Projeto - Fisio Back

---

## 📋 **Pré-requisitos**

Antes de começar, certifique-se de ter instalado:

- **Ruby** 3.2.3 ou superior
- **MongoDB** (rodando localmente ou remoto)
- **Bundler** (gerenciador de gems do Ruby)
- **Git** (para clonar o projeto)

---

## 📦 **1. Clonar o Repositório**

```bash
git clone https://github.com/Jsilva703/fisio_back.git
cd fisio_back
```

---

## 🔧 **2. Instalar Dependências**

```bash
bundle install
```

Isso vai instalar todas as gems necessárias listadas no `Gemfile`:
- Sinatra (framework web)
- Mongoid (ODM para MongoDB)
- Puma (servidor web)
- JWT (autenticação)
- E outras...

---

## 🗄️ **3. Configurar MongoDB**

Edite o arquivo `config/mongoid.yml` com suas credenciais do MongoDB:

```yaml
development:
  clients:
    default:
      database: fisio_development
      hosts:
        - localhost:27017
      options:
        server_selection_timeout: 5
```

**Se usar MongoDB Atlas (nuvem):**
```yaml
development:
  clients:
    default:
      uri: mongodb+srv://usuario:senha@cluster.mongodb.net/fisio_development
```

---

## ▶️ **4. Iniciar o Servidor**

### **Modo Simples:**
```bash
bundle exec rackup -o 0.0.0.0 -p 9292
```

### **Modo Background:**
```bash
bundle exec rackup -o 0.0.0.0 -p 9292 &
```

### **Reiniciar Servidor (matar e iniciar):**
```bash
lsof -ti:9292 | xargs kill -9 2>/dev/null && sleep 2 && bundle exec rackup -o 0.0.0.0 -p 9292 &
```

---

## ✅ **5. Testar se Está Funcionando**

```bash
curl http://localhost:9292/health
```

**Resposta esperada:**
```json
{
  "status": "OK",
  "db": "Connected"
}
```

---

## 🔑 **6. Criar Usuário Machine (Primeiro Acesso)**

O usuário **machine** tem acesso total ao sistema. Crie manualmente no MongoDB:

```javascript
db.users.insertOne({
  name: "Machine",
  email: "machine@system.com",
  password_digest: "$2a$12$...", // Use BCrypt para gerar
  role: "machine",
  company_id: null,
  created_at: new Date(),
  updated_at: new Date()
})
```

Ou use o `test.rb` se existir no projeto.

---

## 📝 **7. Fazer Login**

```bash
curl -X POST 'http://localhost:9292/api/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "machine@system.com",
    "password": "sua_senha"
  }'
```

**Resposta:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "...",
    "name": "Machine",
    "email": "machine@system.com",
    "role": "machine"
  }
}
```

Copie o `token` para usar nos próximos requests!

---

## 🏢 **8. Criar Primeira Empresa**

```bash
curl -X POST 'http://localhost:9292/api/companies' \
  -H 'Authorization: Bearer SEU_TOKEN_MACHINE' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Clínica Exemplo",
    "email": "contato@clinica.com",
    "phone": "(11) 98888-9999",
    "plan": "basic",
    "cnpj": "12.345.678/0001-99"
  }'
```

---

## 👤 **9. Criar Primeiro Admin da Empresa**

```bash
curl -X POST 'http://localhost:9292/api/auth/register' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Admin da Clínica",
    "email": "admin@clinica.com",
    "password": "senha123",
    "role": "admin",
    "company_id": "ID_DA_EMPRESA"
  }'
```

---

## 🎯 **10. Acessar Documentação dos Endpoints**

Consulte os arquivos na pasta `doc_project`:
- `TODOS_CURLS.md` - Todos os 52+ endpoints com exemplos
- `FLUXO_EMPRESA.md` - Fluxo completo na visão empresa
- `ROADMAP.md` - Planejamento das próximas fases

---

## 🛠️ **Comandos Úteis**

### **Ver logs do servidor:**
```bash
tail -f log/development.log  # Se tiver logs
```

### **Parar o servidor:**
```bash
lsof -ti:9292 | xargs kill -9
```

### **Verificar se está rodando:**
```bash
lsof -i:9292
```

### **Acessar console do MongoDB:**
```bash
mongosh
use fisio_development
db.users.find()
```

### **Limpar banco de dados (cuidado!):**
```bash
mongosh fisio_development --eval "db.dropDatabase()"
```

---

## 🐛 **Problemas Comuns**

### **Erro: Address already in use**
```bash
lsof -ti:9292 | xargs kill -9
```

### **Erro: Connection refused (MongoDB)**
Certifique-se de que o MongoDB está rodando:
```bash
sudo systemctl start mongod  # Linux
brew services start mongodb-community  # macOS
```

### **Erro: Gem not found**
```bash
bundle install
```

### **Erro: Cannot load such file**
Verifique se todos os `require_relative` estão corretos no `config.ru`

---

## 🌐 **Deploy (Produção)**

### **Render.com:**
1. Conecte o repositório GitHub
2. Configure as variáveis de ambiente
3. Build Command: `bundle install`
4. Start Command: `bundle exec rackup -o 0.0.0.0 -p $PORT`

### **Heroku:**
```bash
heroku create fisio-back
heroku addons:create mongolab
git push heroku main
```

---

## 📚 **Estrutura do Projeto**

```
fisio_back/
├── app/
│   ├── controllers/      # Controladores das rotas
│   ├── models/          # Modelos Mongoid
│   ├── services/        # Lógica de negócio (Fase 1)
│   └── middleware/      # Autenticação JWT
├── config/
│   └── mongoid.yml     # Configuração MongoDB
├── doc_project/        # Documentação
├── vendor/bundle/      # Gems instaladas
├── config.ru          # Arquivo de inicialização
├── Gemfile           # Dependências
└── README.md         # Resumo do projeto
```

---

## 🆘 **Precisa de Ajuda?**

- 📧 Email: jsilva703@exemplo.com
- 📝 Issues: [GitHub Issues](https://github.com/Jsilva703/fisio_back/issues)

---

**Status:** ✅ Sistema em produção  
**Versão:** 1.0.0  
**Última atualização:** 08/12/2025
