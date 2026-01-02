# frozen_string_literal: true

# Serviços relacionados a agendas
module Schedulings
  class SchedulingsService
    def self.create_or_update(company_id, params_data)
      raise ArgumentError, 'Data é obrigatória' if params_data['date'].nil?

      data = Date.parse(params_data['date'].to_s)

      agenda = Scheduling.where(date: data,
                                company_id: company_id).first || Scheduling.new(
                                  date: data, company_id: company_id
                                )

      agenda.slots = params_data['slots'] || []
      agenda.enabled = params_data['enabled'].to_i
      agenda.professional_id = params_data['professional_id'].to_i
      agenda.room_id = params_data['room_id'] || nil

      raise StandardError, agenda.errors.full_messages.join(', ') unless agenda.save

      agenda
    end

    def self.list_upcoming(company_id)
      Scheduling.where(company_id: company_id, :date.gte => Date.today).asc(:date)
    end

    def self.find_by_date(company_id, date)
      data = Date.parse(date.to_s)
      Scheduling.where(date: data, company_id: company_id).first
    end

    def self.delete_by_date(company_id, date)
      data = Date.parse(date.to_s)
      agenda = Scheduling.where(date: data, company_id: company_id).first
      raise Mongoid::Errors::DocumentNotFound.new(Scheduling, date) unless agenda

      agenda.destroy
      true
    end

    def self.list_by_professional(company_id, professional_id, room_id = nil)
      query = { company_id: company_id, professional_id: professional_id.to_i, :date.gte => Date.today }
      query[:room_id] = room_id.to_i if room_id
      Scheduling.where(query).asc(:date)
    end

    def self.update_by_id(company_id, id, params_data)
      agenda = Scheduling.where(id: id, company_id: company_id).first
      raise Mongoid::Errors::DocumentNotFound.new(Scheduling, id) unless agenda

      agenda.slots = params_data['slots'] if params_data['slots']
      agenda.date = Date.parse(params_data['date']) if params_data['date']
      agenda.professional_id = params_data['professional_id'].to_i if params_data['professional_id']
      agenda.room_id = params_data['room_id'] if params_data['room_id']
      agenda.enabled = params_data['enabled'].to_i if params_data['enabled']

      raise StandardError, agenda.errors.full_messages.join(', ') unless agenda.save

      agenda
    end
  end
end
