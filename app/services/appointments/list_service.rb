# frozen_string_literal: true

module Appointments
  class ListService
    def self.call(env, params)
      company_id = env['current_company_id']
      agendamentos = Appointment.where(company_id: company_id)
      if params && params[:professional_id]
        agendamentos = agendamentos.where(professional_id: params[:professional_id].to_i)
      end
      agendamentos = agendamentos.desc(:appointment_date)
      { status: 200, body: { status: 'success', agendamentos: agendamentos } }
    rescue StandardError => e
      { status: 500, body: { error: 'Erro ao buscar agendamentos', mensagem: e.message } }
    end
  end
end
