# API de Avatares 🖼️

Sistema de upload de fotos de perfil para usuários e profissionais usando Supabase Storage.

## 📋 Configuração

### 1. Variáveis de Ambiente

Adicione ao seu `.env`:

```env
SUPABASE_URL=https://ikxukvsxuokmnlcxffky.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlreHVrdnN4dW9rbW5sY3hmZmt5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2ODIzMTE5NSwiZXhwIjoyMDgzODA3MTk1fQ.YiOQzvB4Af7iOdHbK3KFtxLHrOqhug4sSBIsRX439VI
```

### 2. Criar Bucket no Supabase

1. Acesse o painel do Supabase: https://ikxukvsxuokmnlcxffky.supabase.co
2. Vá em **Storage** → **Create a new bucket**
3. Nome: `avatars`
4. ✅ Marque **Public bucket**
5. Create bucket

### 3. Configurar Políticas (RLS)

No bucket `avatars`, adicione as seguintes políticas:

#### Política de SELECT (leitura pública)
```sql
CREATE POLICY "Allow public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');
```

#### Política de INSERT (permitir uploads)
```sql
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars');
```

#### Política de DELETE (permitir remoção)
```sql
CREATE POLICY "Allow authenticated deletes"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars');
```

### 4. Instalar Dependências

```bash
bundle install
```

## 🚀 Endpoints

### Upload Avatar do Usuário

**POST** `/api/users/:id/avatar`

Faz upload da foto de perfil de um usuário.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body (form-data):**
- `file`: Arquivo de imagem (JPEG, PNG, WebP - máx 5MB)

**Permissões:**
- Usuário pode atualizar seu próprio avatar
- Admin pode atualizar qualquer avatar

**Exemplo (cURL):**
```bash
curl -X POST http://localhost:9292/api/users/6789abc123def456/avatar \
  -H "Authorization: Bearer {seu_token}" \
  -F "file=@/path/to/photo.jpg"
```

**Resposta (200 OK):**
```json
{
  "message": "Avatar atualizado com sucesso",
  "avatar_url": "https://ikxukvsxuokmnlcxffky.supabase.co/storage/v1/object/public/avatars/users/6789abc123def456/uuid-here.jpg",
  "user": {
    "id": "6789abc123def456",
    "name": "João Silva",
    "email": "joao@example.com",
    "avatar_url": "https://...",
    ...
  }
}
```

---

### Remover Avatar do Usuário

**DELETE** `/api/users/:id/avatar`

Remove a foto de perfil de um usuário.

**Headers:**
```
Authorization: Bearer {token}
```

**Exemplo (cURL):**
```bash
curl -X DELETE http://localhost:9292/api/users/6789abc123def456/avatar \
  -H "Authorization: Bearer {seu_token}"
```

**Resposta (200 OK):**
```json
{
  "message": "Avatar removido com sucesso"
}
```

---

### Upload Avatar do Profissional

**POST** `/api/professionals/:id/avatar`

Faz upload da foto de perfil de um profissional.

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body (form-data):**
- `file`: Arquivo de imagem (JPEG, PNG, WebP - máx 5MB)

**Permissões:**
- Usuários da mesma empresa podem atualizar
- Admin pode atualizar qualquer avatar

**Exemplo (cURL):**
```bash
curl -X POST http://localhost:9292/api/professionals/abc123def456/avatar \
  -H "Authorization: Bearer {seu_token}" \
  -F "file=@/path/to/photo.jpg"
```

**Resposta (200 OK):**
```json
{
  "message": "Avatar atualizado com sucesso",
  "avatar_url": "https://ikxukvsxuokmnlcxffky.supabase.co/storage/v1/object/public/avatars/professionals/abc123def456/uuid-here.jpg",
  "professional": {
    "id": "abc123def456",
    "name": "Dr. Maria Santos",
    "specialty": "Fisioterapeuta",
    "avatar_url": "https://...",
    ...
  }
}
```

---

### Remover Avatar do Profissional

**DELETE** `/api/professionals/:id/avatar`

Remove a foto de perfil de um profissional.

**Exemplo (cURL):**
```bash
curl -X DELETE http://localhost:9292/api/professionals/abc123def456/avatar \
  -H "Authorization: Bearer {seu_token}"
```

---

## 📝 Validações

### Tipos de Arquivo Aceitos
- `image/jpeg`
- `image/jpg`
- `image/png`
- `image/webp`

### Tamanho Máximo
- 5MB por arquivo

### Estrutura de Pastas no Bucket
```
avatars/
├── users/
│   ├── {user_id}/
│   │   └── {uuid}.jpg
└── professionals/
    ├── {professional_id}/
    │   └── {uuid}.png
```

---

## 🔒 Segurança

- Upload requer autenticação via JWT
- Apenas o próprio usuário ou admin pode atualizar avatar de usuário
- Apenas usuários da mesma empresa ou admin podem atualizar avatar de profissional
- Arquivos antigos são removidos automaticamente ao fazer novo upload
- Validação de tipo e tamanho de arquivo

---

## ⚙️ Modelos Atualizados

### User
```ruby
field :avatar_url, type: String
```

### Professional
```ruby
field :avatar_url, type: String
```

O campo `avatar_url` agora está disponível em todos os endpoints que retornam usuários ou profissionais.

---

## 🎨 Uso no Frontend (Exemplo React)

```javascript
// Upload de avatar
const uploadAvatar = async (userId, file) => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch(`/api/users/${userId}/avatar`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    },
    body: formData
  });

  return response.json();
};

// Componente de exemplo
const AvatarUpload = ({ userId }) => {
  const handleFileChange = async (e) => {
    const file = e.target.files[0];
    if (file) {
      const result = await uploadAvatar(userId, file);
      console.log('Avatar URL:', result.avatar_url);
    }
  };

  return (
    <input 
      type="file" 
      accept="image/jpeg,image/png,image/webp"
      onChange={handleFileChange}
    />
  );
};
```

---

## 🐛 Troubleshooting

### Erro: "Bucket not found"
- Certifique-se de criar o bucket `avatars` no Supabase Storage

### Erro: "Permission denied"
- Verifique se as políticas RLS estão configuradas corretamente

### Erro: "File too large"
- Tamanho máximo é 5MB. Redimensione a imagem antes do upload

### Erro: "Invalid file type"
- Apenas JPEG, PNG e WebP são aceitos
