# frozen_string_literal: true

# Serviços relacionados a profissionais
module Professionals
  class ProfessionalsService
    def self.list(company_id, params = {})
      query = {}
      query[:company_id] = company_id if company_id

      professionals = Professional.where(query)

      professionals = professionals.where(status: params[:status]) if params[:status]

      professionals = professionals.where(name: /#{Regexp.escape(params[:search])}/i) if params[:search]

      professionals.order_by(professional_id: :asc)
    end

    def self.find_by_company(company_id, professional_id)
      Professional.find_by(company_id: company_id, professional_id: professional_id.to_i)
    end

    def self.find(id)
      Professional.find(id)
    end

    def self.create(company_id, params_data)
      professional = Professional.new(
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        cpf: params_data['cpf'],
        registration_number: params_data['registration_number'],
        specialty: params_data['specialty'],
        color: params_data['color'] || '#3B82F6',
        company_id: company_id
      )

      raise StandardError, professional.errors.full_messages.join(', ') unless professional.save

      professional
    end

    def self.update(company_id, professional_id, params_data)
      professional = find_by_company(company_id, professional_id)
      raise Mongoid::Errors::DocumentNotFound.new(Professional, professional_id) unless professional

      update_fields = {}
      %w[name email phone cpf registration_number specialty color status].each do |f|
        update_fields[f.to_sym] = params_data[f] if params_data.key?(f)
      end

      raise ArgumentError, 'Nenhum campo válido para atualizar' if update_fields.empty?

      raise StandardError, professional.errors.full_messages.join(', ') unless professional.update(update_fields)

      professional
    end

    def self.delete(company_id, professional_id)
      professional = find_by_company(company_id, professional_id)
      raise Mongoid::Errors::DocumentNotFound.new(Professional, professional_id) unless professional

      raise StandardError, 'Profissional possui consultas vinculadas' if professional.appointments.exists?

      professional.destroy
      true
    end
  end
end
