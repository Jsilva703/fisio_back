# frozen_string_literal: true

module Appointments
  class UpdateService
    def self.call(id, params_data, env)
      company_id = env['current_company_id']
      return { status: 400, body: { error: 'Dados não fornecidos' } } if params_data.nil? || params_data.empty?

      appointment = Appointment.where(id: id, company_id: company_id).first
      return { status: 404, body: { error: 'Agendamento não encontrado' } } if appointment.nil?

      if params_data['appointment_date'].present?
        data_hora_nova = Time.parse(params_data['appointment_date'].to_s)
        data_agenda_nova = data_hora_nova.in_time_zone.to_date
        hora_slot_nova = data_hora_nova.in_time_zone.strftime('%H:%M')

        data_hora_antiga = appointment.appointment_date
        data_agenda_antiga = data_hora_antiga.in_time_zone.to_date
        hora_slot_antiga = data_hora_antiga.in_time_zone.strftime('%H:%M')

        agenda_nova = Scheduling.where(date: data_agenda_nova, company_id: company_id).first
        return { status: 404, body: { error: "Agenda não encontrada para #{data_agenda_nova}" } } if agenda_nova.nil?

        unless agenda_nova.reserve_slot(hora_slot_nova)
          return { status: 409, body: { error: "Horário #{hora_slot_nova} não está disponível" } }
        end

        agenda_antiga = Scheduling.where(date: data_agenda_antiga, company_id: company_id).first
        agenda_antiga&.release_slot(hora_slot_antiga)
      end

      appointment.payment_method = params_data['payment_method'] if params_data['payment_method']

      if appointment.update_attributes(params_data)
        { status: 200, body: { status: 'success', agendamento: appointment } }
      else
        if params_data['appointment_date'].present?
          agenda_nova.release_slot(hora_slot_nova) if defined?(agenda_nova) && agenda_nova
          agenda_antiga.reserve_slot(hora_slot_antiga) if defined?(agenda_antiga) && agenda_antiga
        end
        { status: 422, body: { error: 'Erro ao atualizar', detalhes: appointment.errors.messages } }
      end
    rescue StandardError => e
      { status: 500, body: { error: 'Erro interno', mensagem: e.message } }
    end
  end
end
