# frozen_string_literal: true

module Appointments
  class ShowService
    def self.call(id, env)
      company_id = env['current_company_id']
      appointment = Appointment.where(id: id, company_id: company_id).first
      return { status: 404, body: { error: 'Agendamento não encontrado' } } if appointment.nil?

      { status: 200, body: { status: 'success', agendamento: appointment } }
    rescue StandardError => e
      { status: 500, body: { error: 'Erro ao buscar agendamento', mensagem: e.message } }
    end
  end
end
