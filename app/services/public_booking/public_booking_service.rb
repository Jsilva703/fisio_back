# frozen_string_literal: true

# Serviços relacionados a public booking
module PublicBooking
  class PublicBookingService
    def self.available_days(company_id)
      company = Company.find(company_id)
      raise Mongoid::Errors::DocumentNotFound.new(Company, company_id) unless company

      schedulings = Scheduling.where(company_id: company_id, :date.gte => Date.today).order_by(date: :asc)
      available_days = schedulings.select { |s| s.slots.any? && s.enabled.zero? }

      available_days.map do |schedule|
        {
          date: schedule.date,
          slots: schedule.slots,
          available_slots: schedule.slots.count
        }
      end
    end

    def self.available_slots(company_id, date_str)
      company = Company.find(company_id)
      raise Mongoid::Errors::DocumentNotFound.new(Company, company_id) unless company

      date = Date.parse(date_str)
      schedule = Scheduling.where(company_id: company_id, date: date).first
      return nil if schedule.nil? || schedule.enabled != 0

      { date: date, available_slots: schedule.slots, total_slots: schedule.slots.count }
    end

    def self.book(company_id, params_data)
      raise ArgumentError, 'Dados inválidos' if params_data.empty?

      company = Company.find(company_id)
      raise StandardError, 'Empresa inativa ou suspensa' unless company.active?

      data_hora = Time.parse(params_data['appointment_date'].to_s)
      data_agenda = data_hora.in_time_zone.to_date
      hora_slot = data_hora.in_time_zone.strftime('%H:%M')

      agenda = Scheduling.where(date: data_agenda, company_id: company_id).first

      if agenda.nil? || !agenda.slots.include?(hora_slot)
        raise StandardError, "Desculpe, o horário das #{hora_slot} já não está disponível."
      end

      appointment = Appointment.new(
        patient_name: params_data['patient_name'],
        patient_phone: params_data['patient_phone'],
        patiente_document: params_data['patiente_document'] || 'N/A',
        type: params_data['type'] || 'clinic',
        address: params_data['address'],
        appointment_date: data_hora,
        duration: params_data['duration'] || 60,
        price: params_data['price'].to_f,
        company_id: company_id
      )

      raise StandardError, appointment.errors.full_messages.join(', ') unless appointment.save

      # consume slot
      agenda.pull(slots: hora_slot)

      appointment
    end
  end
end
