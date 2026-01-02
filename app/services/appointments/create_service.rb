# frozen_string_literal: true

# Service para criação de agendamento (lógica migrada do controller)
module Appointments
  class CreateService
    def self.call(params_data, env)
      data_hora = Time.parse(params_data['appointment_date'].to_s)
      data_agenda = data_hora.in_time_zone.to_date
      hora_slot = data_hora.in_time_zone.strftime('%H:%M')
      company_id = env['current_company_id']

      agenda = Scheduling.where(date: data_agenda, company_id: company_id).first
      return { status: 404, body: { error: 'Agenda não encontrada para esta data' } } if agenda.nil?

      unless agenda.reserve_slot(hora_slot)
        return { status: 409, body: { error: "Horário #{hora_slot} não está disponível" } }
      end

      patient_id = params_data['patient_id']
      unless patient_id && patient_id.to_s.strip.length.positive?
        agenda.release_slot(hora_slot)
        return { status: 400, body: { error: 'Campo patient_id é obrigatório' } }
      end

      patient = Patient.where(id: patient_id, company_id: company_id).first
      unless patient
        agenda.release_slot(hora_slot)
        return { status: 404, body: { error: 'Paciente não encontrado ou não pertence a esta empresa' } }
      end

      professional_id = params_data['professional_id']
      if professional_id && professional_id.to_s.strip.length.positive?
        professional = Professional.find_by(
          company_id: company_id,
          professional_id: professional_id.to_i
        )

        unless professional
          agenda.release_slot(hora_slot)
          return { status: 404, body: { error: 'Profissional não encontrado' } }
        end

        conflito = Appointment.where(
          company_id: company_id,
          professional_id: professional_id.to_i,
          appointment_date: data_hora
        ).exists?

        if conflito
          agenda.release_slot(hora_slot)
          return { status: 409, body: { error: 'Profissional já possui consulta neste horário' } }
        end
      end

      room_id = params_data['room_id']
      if room_id && room_id.to_s.strip.length.positive?
        room = Room.find_by(
          company_id: company_id,
          room_id: room_id.to_i
        )

        unless room
          agenda.release_slot(hora_slot)
          return { status: 404, body: { error: 'Sala não encontrada' } }
        end

        conflito = Appointment.where(
          company_id: company_id,
          room_id: room_id.to_i,
          appointment_date: data_hora
        ).exists?

        if conflito
          agenda.release_slot(hora_slot)
          return { status: 409, body: { error: 'Sala já está ocupada neste horário' } }
        end
      end

      appointment = Appointment.new(
        patient_id: patient_id,
        patient_name: patient.name,
        patient_phone: patient.phone,
        patiente_document: patient.cpf,
        professional_id: professional_id&.to_i,
        room_id: room_id&.to_i,
        type: params_data['type'] || 'clinic',
        address: params_data['address'],
        appointment_date: data_hora,
        payment_method: params_data['payment_method'],
        price: params_data['price'].to_f,
        company_id: company_id
      )

      return { status: 201, body: { status: 'success', agendamento: appointment } } if appointment.save

      agenda.release_slot(hora_slot)
      { status: 422, body: { error: 'Erro ao salvar', detalhes: appointment.errors.messages } }
    rescue StandardError => e
      { status: 500, body: { error: 'Erro interno', mensagem: e.message } }
    end
  end
end
