# frozen_string_literal: true

# Serviços relacionados a salas
module Rooms
  class RoomsService
    def self.create(company_id, params_data)
      room = Room.new(
        name: params_data['name'],
        description: params_data['description'],
        capacity: params_data['capacity'] || 1,
        color: params_data['color'] || '#10B981',
        company_id: company_id,
        status: params_data['status'] || 'active',
        settings: params_data['settings'] || {}
      )

      raise StandardError, room.errors.full_messages.join(', ') unless room.save

      room
    end

    def self.list(company_id, params = {})
      rooms = Room.where(company_id: company_id)
      rooms = rooms.where(status: params[:status]) if params[:status]
      rooms = rooms.where(name: /#{Regexp.escape(params[:search])}/i) if params[:search]
      rooms.order_by(room_id: :asc)
    end

    def self.find_by_company(company_id, room_id)
      Room.find_by(company_id: company_id, room_id: room_id.to_i)
    end

    def self.update(company_id, room_id, params_data)
      room = find_by_company(company_id, room_id)
      raise Mongoid::Errors::DocumentNotFound.new(Room, room_id) unless room

      update_fields = {}
      %w[name description capacity color status settings].each do |f|
        update_fields[f.to_sym] = params_data[f] if params_data.key?(f)
      end

      raise ArgumentError, 'Dados não fornecidos' if update_fields.empty?

      raise StandardError, room.errors.full_messages.join(', ') unless room.update_attributes(update_fields)

      room
    end

    def self.delete(company_id, room_id)
      room = find_by_company(company_id, room_id)
      raise Mongoid::Errors::DocumentNotFound.new(Room, room_id) unless room

      raise StandardError, 'Erro ao deletar sala' unless room.destroy

      true
    end
  end
end
