Segurança e hardening recomendados

1. Variáveis de ambiente
- Defina `SIDEKIQ_WEB_USER` e `SIDEKIQ_WEB_PASSWORD` com valores fortes no Render.
- Defina `REDIS_URL` apontando para o Redis gerenciado do Render.
- Defina `APP_BASE_URL` para a URL pública da aplicação.

2. Proteção do Sidekiq Web
- Não exponha a UI publicamente sem firewall/allowlist. No Render, use Network / Firewall rules para permitir apenas seu IP ou VPC.
- Use `SIDEKIQ_WEB_USER`/`SIDEKIQ_WEB_PASSWORD` fortes.
- Considere integrar SSO (OAuth) para acesso corporativo.

3. Rate limiting e bloqueio
- `Rack::Attack` foi adicionado com regras básicas. Ajuste `config/initializers/rack_attack.rb` conforme tráfego real.

4. TLS/HTTPS
- Garanta que o tráfego externo passe por HTTPS (Render já oferece TLS). Não exponha portas HTTP sem proxy TLS.

5. Monitoramento e alertas
- Configure logs e alertas para bloqueios e picos de tráfego.
- Monitorar métricas de Sidekiq / Redis (jobs enfileirados, latência).

6. Outras recomendações
- Habilitar CSP, HSTS e outras headers de segurança no `config.ru` se servir front-end.
- Atualizar gems regularmente e rodar `bundle audit` / `brakeman` periodicamente.
- Use senhas/segredos no serviço de variáveis do Render — nunca commitar senhas no repositório.
