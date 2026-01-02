# frozen_string_literal: true

# Job para verificar pagamentos atrasados e suspender empresas
# Este job deve ser executado diariamente via cron

require 'date'

class CheckOverduePayments
  def self.run
    puts "[#{Time.now}] Iniciando verificação de pagamentos atrasados..."

    # Busca todas as empresas ativas com data de vencimento
    companies = Company.where(
      status: 'active',
      :billing_due_date.ne => nil
    )

    today = Date.today.to_s # Converter para String formato "YYYY-MM-DD"
    overdue_count = 0

    companies.each do |company|
      # Verifica se a data de vencimento já passou (comparação de strings)
      next unless company.billing_due_date < today

      puts "  - Empresa #{company.name} (#{company.slug}) com pagamento atrasado desde #{company.billing_due_date}"
      company.mark_as_overdue!
      overdue_count += 1

      # Aqui você pode adicionar lógica para enviar email de notificação
      # send_overdue_notification(company)
    end

    puts "[#{Time.now}] Verificação concluída. #{overdue_count} empresa(s) suspensa(s)."

    overdue_count
  end

  # Método auxiliar para enviar notificações (implementar conforme necessidade)
  def self.send_overdue_notification(company)
    # TODO: Integrar com serviço de email
    puts "    * Enviando notificação para #{company.email}"
  end
end
