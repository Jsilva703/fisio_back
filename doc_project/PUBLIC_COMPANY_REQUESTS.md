# Solicitação pública de criação de empresa

Resumo rápido
- Front público envia os dados de empresa + escolha de plano para o backend.
- O backend NÃO cria a `Company`; salva um registro `CompanyRequest` com `status: pending` e publica um evento Redis para o painel `machine`.

Endpoints principais

1) POST /api/public/company_requests

- Descrição: cria uma solicitação pública para análise/criação manual pela equipe (machine). Não cria `Company`.
- Headers obrigatórios:
  - `Content-Type: application/json`
  - `Accept: application/json`

- Curl (exemplo):

```bash
curl -i -X POST 'https://api.seudominio.com/api/public/company_requests' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -d '{
    "name": "Clínica Exemplo LTDA",
    "email": "contato@clinicaexemplo.com",
    "plan": "professional",
    "document": "12345678909",    # aceita CPF (11 dígitos) ou CNPJ (14 dígitos)
    "phone": "+55 11 98765-4321",
    "country": "BR",
    "state": "SP",
    "city": "São Paulo",
    "address": "Av. Paulista, 1000, Sala 101",
    "zip": "01310-100",
    "max_users": 10,
    "notes": "Cliente vem pelo formulário público; preferir contato por WhatsApp",
    "referrer": "marketing_campaign_2026",
    "utm_source": "facebook",
    "utm_campaign": "lancamento"
  }'
```

- Body (JSON) — campos aceitos (os obrigatórios estão em negrito):
  - name (string) — obrigatório
  - email (string) — obrigatório
  - plan (string) — obrigatório (ex.: `free`, `professional`, `enterprise`)
  - phone (string)
  - document (string) — aceita CPF (11 dígitos) ou CNPJ (14 dígitos). Pode ser enviado como `document`, `cpf` ou `cnpj`. O backend normaliza para dígitos e popula `document_type`.
  - country, state, city, address, zip (strings)
  - max_users (integer)
  - notes (string)
  - referrer, utm_source, utm_campaign (strings)

- Resposta (201 Created) — exemplo:

```json
{
  "id": "64f2a1c3e9b1f6a0d3c4b5a6",
  "name": "Clínica Exemplo LTDA",
  "email": "contato@clinicaexemplo.com",
  "plan": "professional",
  "phone": "+55 11 98765-4321",
  "status": "pending",
  "created_at": "2026-01-05T12:34:56Z"
}
```

- Erros comuns:
  - 400 Bad Request — JSON inválido
  - 422 Unprocessable Entity — validação falhou (campo faltando ou formato errado)

2) GET /api/machine/companies/stream (SSE)

- Descrição: endpoint SSE público consumido pelo painel `machine` para receber eventos em tempo real. O backend publica dois canais Redis: `companies:requested` (quando uma `CompanyRequest` é criada) e `companies:new` (quando uma `Company` é criada pelo machine). O SSE foi atualizado para assinar ambos os canais.
- Curl de teste (mantém a conexão aberta):

```bash
curl -N 'https://api.seudominio.com/api/machine/companies/stream'
```

- Formato das mensagens recebidas (cada evento é uma linha `data: <json>\n\n`):

```json
{
  "type": "requested", // ou "created"
  "payload": { ... }   // objeto com os dados da request ou da company criada
}
```

- Exemplos de payloads:
  - Evento `requested` (empresa solicitada):

```json
{
  "type": "requested",
  "payload": {
    "id": "64f2a1c3e9b1f6a0d3c4b5a6",
    "name": "Clínica Exemplo LTDA",
    "email": "contato@clinicaexemplo.com",
    "plan": "professional",
    "phone": "+55 11 98765-4321",
    "status": "pending",
    "created_at": "2026-01-05T12:34:56Z",
    "notes": "Cliente vem pelo formulário público; preferir contato por WhatsApp"
  }
}
```

  - Evento `created` (empresa criada pelo painel machine):

```json
{
  "type": "created",
  "payload": {
    "id": "6500b2d4a1c2d3e4f5a6b7c8",
    "name": "Clínica Exemplo LTDA",
    "slug": "clinica-exemplo-ltda",
    "plan": "professional",
    "trial_ends_at": "2026-01-12T12:00:00Z",
    "status": "active",
    "created_at": "2026-01-06T09:00:00Z"
  }
}
```

Mapeamento recomendado para a tela `machine`
- Endpoint a ser usado para a lista em tempo real: `GET /api/machine/companies/stream` (SSE). Use o campo `type` para distinguir eventos:
  - `requested`: mostrar novo item na lista de solicitações pendentes (com ação "Aceitar" / "Rejeitar" / "Pedir mais informações").
  - `created`: indicar que a empresa foi criada — atualizar/remover item da fila.

- Campos mínimos a exibir na listagem:
  - `name`, `email`, `plan`, `phone`, `created_at`, `status`, `referrer`/`utm`, `notes`.

- Campos no detalhe (ao abrir request):
  - `address`, `city`, `state`, `country`, `zip`, `max_users`, `notes`, histórico de interações.

Exemplo de consumo em JavaScript (EventSource):

```javascript
const es = new EventSource('https://api.seudominio.com/api/machine/companies/stream');

es.onmessage = (e) => {
  try {
    const data = JSON.parse(e.data);
    // data.type => 'requested' | 'created'
    // data.payload => objeto com campos
    if (data.type === 'requested') {
      // adicionar à fila de solicitações
    } else if (data.type === 'created') {
      // atualizar UI: empresa criada
    }
  } catch (err) {
    console.error('SSE parse error', err);
  }
};

es.onerror = (err) => {
  console.error('SSE connection error', err);
};
```

Notas e recomendações
- Confirme com o time de frontend os nomes exatos dos planos (`plan`) para validar no formulário.
- Se for necessário um endpoint REST para listar `CompanyRequest` (paginado/filtrável) eu posso adicionar `GET /api/machine/company_requests` para facilitar o carregamento inicial da tela (recomendado).

Arquivo desta documentação: `doc_project/PUBLIC_COMPANY_REQUESTS.md`
