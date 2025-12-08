# 🚀 Roadmap de Desenvolvimento - Fisio Back

---

## ✅ **FASE 0 - Sistema Base (Concluído)**
- Multi-tenant com isolamento por empresa
- Autenticação JWT (machine, admin, user)
- Gestão de pacientes, consultas, agendas e prontuários
- APIs públicas para agendamento online
- Sistema de cobrança/assinaturas
- LGPD compliance

---

## 📋 **FASE 1 - Multi-Profissional e Multi-Sala**

**Objetivo:** Permitir que clínicas tenham múltiplos profissionais e salas, cada um com sua própria agenda.

**O que precisa:**
- Criar cadastro de Profissionais (nome, especialidade, CPF, registro profissional)
- Criar cadastro de Salas/Consultórios (nome, capacidade)
- Vincular agendas a profissionais específicos
- Vincular agendas a salas específicas
- Validar disponibilidade considerando profissional + sala + horário
- Evitar conflitos (mesmo profissional em dois lugares ao mesmo tempo)

**Impacto:**
- Clínicas com múltiplos fisioterapeutas podem gerenciar melhor
- Permite visualização por profissional ou por sala
- Essencial para clínicas maiores

---

## 🎯 **FASE 2 - Planos por Funcionalidade**

**Objetivo:** Controlar o que cada empresa pode acessar baseado no plano contratado.

**O que precisa:**
- Definir lista de features disponíveis (prontuário, multi-profissional, WhatsApp, etc)
- Criar matriz: qual plano tem acesso a quais features
- Bloquear endpoints baseado nas features do plano da empresa
- Adicionar limites por plano (ex: Basic = máx 50 consultas/mês, 100 pacientes)
- Mostrar upgrades disponíveis quando limite for atingido

**Exemplos de restrições:**
- **Basic:** Só agendamento simples, sem prontuário
- **Professional:** Adiciona prontuário + multi-profissional (até 3)
- **Premium:** Tudo + analytics + mais usuários
- **Enterprise:** Sem limites + WhatsApp + API access

---

## 📊 **FASE 3 - Analytics e Dashboard Machine**

**Objetivo:** Você (machine) ter visão completa do negócio SaaS.

**O que precisa:**
- Dashboard com métricas gerais (total empresas, usuários, consultas)
- Receita: MRR, ARR, churn rate, growth rate
- Ranking de empresas mais ativas
- Empresas com risco de cancelamento
- Horários de pico de uso no sistema
- Logs de atividade (quem fez o quê, quando)
- Alertas automáticos (pagamento atrasado, limite atingido)
- Relatórios exportáveis

**Impacto:**
- Você toma decisões baseadas em dados
- Identifica problemas antes que virem cancelamentos
- Vê quais features são mais usadas

---

## 💬 **FASE 4 - Integração WhatsApp (Evolution API)**

**Objetivo:** Automação de comunicação com pacientes via WhatsApp.

**O que precisa:**
- Conectar conta WhatsApp da empresa ao sistema
- Templates de mensagens (confirmação, lembrete, pós-consulta)
- Envio automático de:
  - Confirmação quando consulta é criada
  - Lembrete 24h antes
  - Mensagem de follow-up pós-consulta
- Histórico de mensagens trocadas com paciente
- Chat manual (recepcionista responde via sistema)
- Webhook para receber respostas (paciente confirma/cancela)
- Status de entrega (enviado, entregue, lido)

**Tecnologia:**
- Evolution API (API WhatsApp multi-device)
- Webhooks para comunicação bidirecional
- Background jobs para envios agendados

**Impacto:**
- **MAIOR** diferencial competitivo
- Reduz no-show (lembretes automáticos)
- Melhora experiência do paciente
- Economiza tempo da recepção

---

## 🎯 **Resumo das Prioridades:**

1. **Fase 1** → Essencial para clínicas com múltiplos profissionais *(urgência média)*
2. **Fase 2** → Importante para monetização diferenciada *(urgência média)*
3. **Fase 3** → Útil para você gerenciar o negócio *(pode esperar)*
4. **Fase 4** → **GAME CHANGER** para vendas *(máxima prioridade quando pronto)*

---

**Status Atual:** Fase 0 concluída ✅  
**Próximo Passo:** Definir qual fase implementar primeiro
