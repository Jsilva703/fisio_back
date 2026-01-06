# frozen_string_literal: true

# Serviços relacionados a companies
module Companies
  class CompaniesService
    def self.list_all
      Company.all
    end
  end
end

# Serviços relacionados a companies
module Companies
  class CompaniesService
    def self.list_all
      Company.all.order_by(created_at: :desc)
    end

    def self.find(id)
      Company.find(id)
    end

    def self.create(params_data)
      company = Company.new(
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        cnpj: params_data['cnpj'],
        address: params_data['address'],
        plan: params_data['plan'] || 'basic',
        status: params_data['status'] || 'active',
        max_users: params_data['max_users'] || 5,
        settings: params_data['settings'] || {}
      )

      raise StandardError, company.errors.full_messages.join(', ') unless company.save

      company
    end

    def self.update(id, params_data)
      company = find(id)

      allowed_fields = %w[
        name email phone cnpj address
        plan status max_users settings
      ]

      update_data = params_data.select { |k, _| allowed_fields.include?(k) }
      raise ArgumentError, 'Nenhum campo válido para atualizar' if update_data.empty?

      if update_data['plan'] && !%w[free basic standard professional premium enterprise].include?(update_data['plan'])
        raise ArgumentError, 'Plano inválido. Opções: basic, professional, premium, enterprise'
      end

      if update_data['status'] && !%w[active inactive suspended pending].include?(update_data['status'])
        raise ArgumentError, 'Status inválido. Opções: active, inactive, suspended, pending'
      end

      if update_data['max_users'] && update_data['max_users'].to_i < 1
        raise ArgumentError, 'max_users deve ser maior que 0'
      end

      raise StandardError, company.errors.full_messages.join(', ') unless company.update(update_data)

      company
    end

    def self.delete(id)
      company = find(id)

      if company.users.exists? || company.appointments.exists? || company.schedulings.exists?
        raise StandardError,
              "Não é possível deletar empresa com dados associados; users=#{company.users_count}; appointments=#{company.appointments_count}; schedulings=#{company.schedulings_count}"
      end

      company.delete
      true
    end

    def self.stats(id)
      company = find(id)

      users = company.users.to_a
      appointments = company.appointments.to_a

      total_revenue = appointments.sum { |a| a.price.to_f }
      appointments_by_status = appointments.group_by(&:status).transform_values(&:count)
      appointments_by_payment = appointments.group_by(&:payment_status).transform_values(&:count)

      {
        status: 'success',
        company_id: company.id.to_s,
        company_name: company.name,
        stats: {
          users: {
            total: users.count,
            max_allowed: company.max_users,
            by_role: users.group_by(&:role).transform_values(&:count)
          },
          appointments: {
            total: appointments.count,
            by_status: appointments_by_status,
            by_payment: appointments_by_payment,
            total_revenue: total_revenue
          },
          schedulings: {
            total: company.schedulings_count
          }
        }
      }
    end
  end
end
