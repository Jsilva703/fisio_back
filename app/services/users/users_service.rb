# frozen_string_literal: true

# Serviços relacionados a users
module Users
  class UsersService
    def self.list(current_user_role, current_company_id, params = {})
      query = {}

      if current_user_role == 'admin'
        query[:company_id] = current_company_id
      elsif params[:company_id]
        query[:company_id] = params[:company_id]
      end

      query[:role] = params[:role] if params[:role]
      query[:status] = params[:status] if params[:status]

      users = User.where(query).order_by(created_at: :desc)

      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 20).to_i
      total = users.count
      users = users.skip((page - 1) * per_page).limit(per_page)

      users.map do |user|
        {
          id: user.id.to_s,
          name: user.name,
          email: user.email,
          role: user.role,
          phone: user.phone,
          status: user.status,
          avatar_url: user.avatar_url,
          company_id: user.company_id&.to_s,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end.then do |users_data|
        {
          status: 'success',
          total: total,
          page: page,
          per_page: per_page,
          total_pages: (total.to_f / per_page).ceil,
          users: users_data
        }
      end
    end

    def self.find(id)
      User.find(id)
    end

    def self.create(admin_company_id, params_data)
      raise ArgumentError, 'Email é obrigatório' if params_data['email'].to_s.strip.empty?
      raise ArgumentError, 'Senha é obrigatória' if params_data['password'].to_s.strip.empty?

      raise StandardError, 'Email já cadastrado' if User.where(email: params_data['email']).exists?

      company = Company.find(admin_company_id)
      raise StandardError, "Limite de usuários atingido para o plano #{company.plan}" unless company.can_add_user?

      role = params_data['role'] || 'user'
      raise ArgumentError, "Role inválida. Use 'user' ou 'admin'" unless %w[user admin].include?(role)

      user = User.new(
        name: params_data['name'],
        email: params_data['email'],
        password: params_data['password'],
        phone: params_data['phone'],
        role: role,
        company_id: admin_company_id,
        status: 'active'
      )

      raise StandardError, user.errors.full_messages.join(', ') unless user.save

      user
    end

    def self.update(current_user_role, current_company_id, current_user_id, id, params_data)
      user = User.find(id)

      raise StandardError, 'Acesso negado' if current_user_role == 'admin' && user.company_id.to_s != current_company_id

      if user.id.to_s == current_user_id && params_data['role']
        raise StandardError, 'Você não pode alterar sua própria role'
      end

      allowed_fields = %w[name email status role phone]
      update_data = params_data.select { |k, _| allowed_fields.include?(k) }

      if update_data['email'] && update_data['email'] != user.email && User.where(email: update_data['email']).exists?
        raise StandardError, 'Email já cadastrado'
      end

      raise StandardError, user.errors.full_messages.join(', ') unless user.update_attributes(update_data)

      user
    end

    def self.delete(current_user_role, current_company_id, current_user_id, id)
      user = User.find(id)

      raise StandardError, 'Apenas administradores podem deletar usuários' unless current_user_role == 'admin'

      raise StandardError, 'Acesso negado' if user.company_id.to_s != current_company_id

      raise StandardError, 'Você não pode deletar sua própria conta' if user.id.to_s == current_user_id

      user.destroy
      true
    end
  end
end
