# 🖼️ API de Avatares - Exemplos cURL

## 👤 USUÁRIOS

### 1. Upload Avatar do Usuário
```bash
curl -X POST http://localhost:9292/api/users/USER_ID_AQUI/avatar \
  -H "Authorization: Bearer SEU_TOKEN_JWT" \
  -F "file=@/caminho/para/foto.jpg"
```

**Retorno (200 OK):**
```json
{
  "message": "Avatar atualizado com sucesso",
  "avatar_url": "https://ikxukvsxuokmnlcxffky.supabase.co/storage/v1/object/public/avatars/users/678a1b2c3d4e5f6789012345/a1b2c3d4-e5f6-7890-1234-567890abcdef.jpg",
  "user": {
    "_id": {
      "$oid": "678a1b2c3d4e5f6789012345"
    },
    "name": "João Silva",
    "email": "joao@example.com",
    "role": "gestor",
    "phone": "11999999999",
    "status": "active",
    "company_id": {
      "$oid": "678a1b2c3d4e5f6789012346"
    },
    "avatar_url": "https://ikxukvsxuokmnlcxffky.supabase.co/storage/v1/object/public/avatars/users/678a1b2c3d4e5f6789012345/a1b2c3d4-e5f6-7890-1234-567890abcdef.jpg",
    "created_at": "2026-01-12T10:00:00.000Z",
    "updated_at": "2026-01-12T15:30:00.000Z"
  }
}
```

**Erros Possíveis:**

**400 - Arquivo não enviado:**
```json
{
  "error": "Nenhum arquivo foi enviado"
}
```

**400 - Tipo de arquivo inválido:**
```json
{
  "error": "Tipo de arquivo não permitido"
}
```

**400 - Arquivo muito grande:**
```json
{
  "error": "Arquivo muito grande (máximo 5MB)"
}
```

**403 - Sem permissão:**
```json
{
  "error": "Sem permissão para atualizar este avatar"
}
```

**404 - Usuário não encontrado:**
```json
{
  "error": "Usuário não encontrado"
}
```

---

### 2. Remover Avatar do Usuário
```bash
curl -X DELETE http://localhost:9292/api/users/USER_ID_AQUI/avatar \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

**Retorno (200 OK):**
```json
{
  "message": "Avatar removido com sucesso"
}
```

**Erros Possíveis:**

**400 - Sem avatar:**
```json
{
  "error": "Usuário não possui avatar"
}
```

---

## 👨‍⚕️ PROFISSIONAIS

### 3. Upload Avatar do Profissional
```bash
curl -X POST http://localhost:9292/api/professionals/PROFESSIONAL_ID_AQUI/avatar \
  -H "Authorization: Bearer SEU_TOKEN_JWT" \
  -F "file=@/caminho/para/foto.png"
```

**Retorno (200 OK):**
```json
{
  "message": "Avatar atualizado com sucesso",
  "avatar_url": "https://ikxukvsxuokmnlcxffky.supabase.co/storage/v1/object/public/avatars/professionals/678a1b2c3d4e5f6789012347/b2c3d4e5-f678-9012-3456-7890abcdef12.png",
  "professional": {
    "_id": {
      "$oid": "678a1b2c3d4e5f6789012347"
    },
    "professional_id": 10,
    "name": "Dr. Maria Santos",
    "email": "maria@example.com",
    "phone": "11988888888",
    "cpf": "12345678900",
    "registration_number": "CREFITO-12345",
    "specialty": "Fisioterapeuta",
    "color": "#3B82F6",
    "status": "active",
    "company_id": {
      "$oid": "678a1b2c3d4e5f6789012346"
    },
    "avatar_url": "https://ikxukvsxuokmnlcxffky.supabase.co/storage/v1/object/public/avatars/professionals/678a1b2c3d4e5f6789012347/b2c3d4e5-f678-9012-3456-7890abcdef12.png",
    "created_at": "2026-01-10T08:00:00.000Z",
    "updated_at": "2026-01-12T15:45:00.000Z"
  }
}
```

**Erros Possíveis:**

**403 - Sem permissão:**
```json
{
  "error": "Sem permissão para atualizar este avatar"
}
```

**404 - Profissional não encontrado:**
```json
{
  "error": "Profissional não encontrado"
}
```

---

### 4. Remover Avatar do Profissional
```bash
curl -X DELETE http://localhost:9292/api/professionals/PROFESSIONAL_ID_AQUI/avatar \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

**Retorno (200 OK):**
```json
{
  "message": "Avatar removido com sucesso"
}
```

**Erros Possíveis:**

**400 - Sem avatar:**
```json
{
  "error": "Profissional não possui avatar"
}
```

---

## 🎨 Exemplo Frontend (JavaScript/React)

### Upload de Avatar - Usuário
```javascript
const uploadUserAvatar = async (userId, file) => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch(`/api/users/${userId}/avatar`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('token')}`
    },
    body: formData
  });

  const data = await response.json();
  
  if (response.ok) {
    console.log('Avatar URL:', data.avatar_url);
    return data;
  } else {
    throw new Error(data.error);
  }
};
```

### Upload de Avatar - Profissional
```javascript
const uploadProfessionalAvatar = async (professionalId, file) => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch(`/api/professionals/${professionalId}/avatar`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('token')}`
    },
    body: formData
  });

  const data = await response.json();
  
  if (response.ok) {
    console.log('Avatar URL:', data.avatar_url);
    return data;
  } else {
    throw new Error(data.error);
  }
};
```

### Componente de Upload (React)
```jsx
import { useState } from 'react';

const AvatarUpload = ({ userId, currentAvatar, onSuccess }) => {
  const [uploading, setUploading] = useState(false);
  const [preview, setPreview] = useState(currentAvatar);

  const handleFileChange = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    // Validações
    if (!file.type.match(/image\/(jpeg|jpg|png|webp)/)) {
      alert('Apenas imagens JPG, PNG ou WebP são permitidas');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      alert('Imagem muito grande (máximo 5MB)');
      return;
    }

    // Preview local
    const reader = new FileReader();
    reader.onloadend = () => setPreview(reader.result);
    reader.readAsDataURL(file);

    // Upload
    setUploading(true);
    try {
      const result = await uploadUserAvatar(userId, file);
      setPreview(result.avatar_url);
      onSuccess?.(result.avatar_url);
    } catch (error) {
      alert(error.message);
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="avatar-upload">
      <div className="avatar-preview">
        <img 
          src={preview || '/default-avatar.png'} 
          alt="Avatar"
          className="w-24 h-24 rounded-full object-cover"
        />
      </div>
      
      <label className="btn-upload">
        {uploading ? 'Enviando...' : 'Escolher foto'}
        <input
          type="file"
          accept="image/jpeg,image/jpg,image/png,image/webp"
          onChange={handleFileChange}
          disabled={uploading}
          className="hidden"
        />
      </label>
    </div>
  );
};
```

---

## 📝 Notas Importantes

### Tipos de Arquivo Aceitos
- `image/jpeg`
- `image/jpg`
- `image/png`
- `image/webp`

### Tamanho Máximo
- **5MB** por arquivo

### Permissões

**Usuários:**
- ✅ Próprio usuário pode atualizar seu avatar
- ✅ Admin pode atualizar avatar de qualquer usuário

**Profissionais:**
- ✅ Usuários da mesma empresa podem atualizar
- ✅ Admin pode atualizar avatar de qualquer profissional

### URLs Públicas
As URLs geradas são públicas e acessíveis sem autenticação:
```
https://ikxukvsxuokmnlcxffky.supabase.co/storage/v1/object/public/avatars/users/{user_id}/{uuid}.jpg
https://ikxukvsxuokmnlcxffky.supabase.co/storage/v1/object/public/avatars/professionals/{professional_id}/{uuid}.png
```

### Estrutura no Bucket
```
avatars/
├── users/
│   ├── {user_id}/
│   │   └── {uuid}.{ext}
└── professionals/
    ├── {professional_id}/
    │   └── {uuid}.{ext}
```

### Comportamento
- ✅ Upload de novo avatar **remove automaticamente** o anterior
- ✅ Apenas 1 avatar por usuário/profissional
- ✅ UUID único para evitar cache de navegador
- ✅ Validação de tipo e tamanho no backend
