# frozen_string_literal: true

module Appointments
  class DeleteService
    def self.call(id, env)
      company_id = env['current_company_id']
      appointment = Appointment.where(id: id, company_id: company_id).first
      return { status: 404, body: { error: 'Agendamento não encontrado' } } if appointment.nil?

      data_hora = appointment.appointment_date
      data_agenda = data_hora.in_time_zone.to_date
      hora_slot = data_hora.in_time_zone.strftime('%H:%M')

      if appointment.destroy
        agenda = Scheduling.where(date: data_agenda, company_id: company_id).first
        agenda&.release_slot(hora_slot)
        { status: 200, body: { status: 'success', mensagem: 'Agendamento cancelado e horário liberado' } }
      else
        { status: 422, body: { error: 'Erro ao cancelar' } }
      end
    rescue StandardError => e
      { status: 500, body: { error: 'Erro ao deletar', mensagem: e.message } }
    end
  end
end
