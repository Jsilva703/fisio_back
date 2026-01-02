# Integração Front — Checkout (payments externalizados)

Este documento foi simplificado: o projeto não contém integração ativa com um gateway de pagamento.

# Integração Front — Checkout (payments externalizados)

O backend não contém integração ativa com nenhum gateway de pagamento. Todas as operações de cobrança (criação de preferências, pagamentos por cartão, PIX, tokenização de cartões, etc.) devem ser realizadas diretamente no painel do provedor de pagamento que você escolher.

Pontos principais:
- Não exponha chaves secretas no front-end.
- Configure webhooks no painel do provedor para notificar o backend sobre pagamentos concluídos; o backend aceitará notificações, mas não cria preferências nem processa pagamentos.
- Se precisar, eu posso gerar um guia específico para o provedor escolhido (ex.: Stripe, Mercado Pago) com exemplos passo-a-passo para o front.

Endpoints do backend relacionados a billing permanecem como pontos de integração simples (status 410 para criação de pagamentos), portanto o front deve operar diretamente com o painel do provedor quando necessário.
    - Para PIX: envie `"method": "pix"` no body (não é necessário `card_token`). Backend retorna dados do QR code quando aplicável.
