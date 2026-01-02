# frozen_string_literal: true

module Users
  class UsersController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json

      # Verificar autenticação
      halt 401, { error: 'Não autenticado' }.to_json unless env['current_user_id']

      @current_user_id = env['current_user_id']
      @current_company_id = env['current_company_id']
      @current_user_role = env['current_user_role']

      # Parse JSON body
      if request.content_type&.include?('application/json') && request.body.read.length.positive?
        request.body.rewind
        env['parsed_json'] = JSON.parse(request.body.read)
      end
    end

    # --- LISTAR USUÁRIOS DA EMPRESA ---
    get '/' do
      unless %w[admin machine].include?(@current_user_role)
        status 403
        return { error: 'Acesso negado' }.to_json
      end

      result = Users::UsersService.list(@current_user_role, @current_company_id, params)
      status 200
      result.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao listar usuários', message: e.message }.to_json
    end

    # --- BUSCAR USUÁRIO POR ID ---
    get '/:id' do
      user = Users::UsersService.find(params[:id])

      if @current_user_role == 'admin' && user.company_id.to_s != @current_company_id
        status 403
        return { error: 'Acesso negado' }.to_json
      end

      status 200
      {
        status: 'success',
        user: {
          id: user.id.to_s,
          name: user.name,
          email: user.email,
          role: user.role,
          status: user.status,
          phone: user.phone,
          company_id: user.company_id&.to_s,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Usuário não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar usuário', message: e.message }.to_json
    end

    # --- CRIAR USUÁRIO (ADMIN CRIA PARA SUA EMPRESA) ---
    post '/' do
      params_data = env['parsed_json'] || {}

      # Apenas admin pode criar usuários
      unless @current_user_role == 'admin'
        status 403
        return { error: 'Apenas administradores podem criar usuários' }.to_json
      end

      # Validações
      if params_data['email'].to_s.strip.empty?
        status 400
        return { error: 'Email é obrigatório' }.to_json
      end

      if params_data['password'].to_s.strip.empty?
        status 400
        return { error: 'Senha é obrigatória' }.to_json
      end

      # Verificar se email já existe
      if User.where(email: params_data['email']).exists?
        status 409
        return { error: 'Email já cadastrado' }.to_json
      end

      # Verificar limite de usuários da empresa
      company = Company.find(@current_company_id)

      unless company.can_add_user?
        status 403
        return { error: "Limite de usuários atingido para o plano #{company.plan}" }.to_json
      end

      # Role padrão é 'user', admin pode criar outro admin
      role = params_data['role'] || 'user'
      unless %w[user admin].include?(role)
        status 400
        return { error: "Role inválida. Use 'user' ou 'admin'" }.to_json
      end

      user = Users::UsersService.create(@current_company_id, params_data)

      status 201
      {
        status: 'success',
        message: 'Usuário criado com sucesso',
        user: {
          id: user.id.to_s,
          name: user.name,
          phone: user.phone,
          email: user.email,
          role: user.role,
          company_id: user.company_id.to_s
        }
      }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao criar usuário', message: e.message }.to_json
    end

    # --- ATUALIZAR USUÁRIO ---
    put '/:id' do
      params_data = env['parsed_json'] || {}
      user = Users::UsersService.update(@current_user_role, @current_company_id, @current_user_id, params[:id],
                                        params_data)

      status 200
      {
        status: 'success',
        message: 'Usuário atualizado com sucesso',
        user: {
          id: user.id.to_s,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          status: user.status
        }
      }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Usuário não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao atualizar usuário', message: e.message }.to_json
    end

    # --- DELETAR USUÁRIO ---
    delete '/:id' do
      Users::UsersService.delete(@current_user_role, @current_company_id, @current_user_id, params[:id])

      status 200
      { status: 'success', message: 'Usuário deletado com sucesso' }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Usuário não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao deletar usuário', message: e.message }.to_json
    end
  end
end
