class UsersController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
    
    # Verificar autenticação
    unless env['current_user_id']
      halt 401, { error: 'Não autenticado' }.to_json
    end
    
    @current_user_id = env['current_user_id']
    @current_company_id = env['current_company_id']
    @current_user_role = env['current_user_role']
    
    # Parse JSON body
    if request.content_type&.include?('application/json') && request.body.read.length > 0
      request.body.rewind
      env['parsed_json'] = JSON.parse(request.body.read)
    end
  end

  # --- LISTAR USUÁRIOS DA EMPRESA ---
  get '/' do
    begin
      # Apenas admin ou machine podem listar usuários
      unless ['admin', 'machine'].include?(@current_user_role)
        status 403
        return { error: 'Acesso negado' }.to_json
      end
      
      query = {}
      
      # Machine pode ver todas as empresas, admin só a sua
      if @current_user_role == 'admin'
        query[:company_id] = @current_company_id
      elsif params[:company_id]
        query[:company_id] = params[:company_id]
      end
      
      # Filtros
      query[:role] = params[:role] if params[:role]
      query[:status] = params[:status] if params[:status]
      
      users = User.where(query).order_by(created_at: :desc)
      
      # Paginação
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 20).to_i
      total = users.count
      users = users.skip((page - 1) * per_page).limit(per_page)
      
      users_data = users.map do |user|
        {
          id: user.id.to_s,
          name: user.name,
          email: user.email,
          role: user.role,
          phone: user.phone,
          status: user.status,
          company_id: user.company_id&.to_s,
          created_at: user.created_at,
          updated_at: user.updated_at
        }
      end
      
      status 200
      {
        status: 'success',
        total: total,
        page: page,
        per_page: per_page,
        total_pages: (total.to_f / per_page).ceil,
        users: users_data
      }.to_json
      
    rescue => e
      status 500
      { error: "Erro ao listar usuários", message: e.message }.to_json
    end
  end

  # --- BUSCAR USUÁRIO POR ID ---
  get '/:id' do
    begin
      user = User.find(params[:id])
      
      # Validar acesso: admin só vê usuários da mesma empresa
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
      { error: "Usuário não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar usuário", message: e.message }.to_json
    end
  end

  # --- CRIAR USUÁRIO (ADMIN CRIA PARA SUA EMPRESA) ---
  post '/' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Apenas admin pode criar usuários
      unless @current_user_role == 'admin'
        status 403
        return { error: 'Apenas administradores podem criar usuários' }.to_json
      end
      
      # Validações
      if params_data['email'].to_s.strip.empty?
        status 400
        return { error: "Email é obrigatório" }.to_json
      end
      
      if params_data['password'].to_s.strip.empty?
        status 400
        return { error: "Senha é obrigatória" }.to_json
      end
      
      # Verificar se email já existe
      if User.where(email: params_data['email']).exists?
        status 409
        return { error: "Email já cadastrado" }.to_json
      end
      
      # Verificar limite de usuários da empresa
      company = Company.find(@current_company_id)
      
      unless company.can_add_user?
        status 403
        return { error: "Limite de usuários atingido para o plano #{company.plan}" }.to_json
      end
      
      # Role padrão é 'user', admin pode criar outro admin
      role = params_data['role'] || 'user'
      unless ['user', 'admin'].include?(role)
        status 400
        return { error: "Role inválida. Use 'user' ou 'admin'" }.to_json
      end
      
      # Criar usuário
      user = User.new(
        name: params_data['name'],
        email: params_data['email'],
        password: params_data['password'],
        phone: params_data['phone'],
        role: role,
        company_id: @current_company_id,
        status: 'active'
      )
      
      if user.save
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
      else
        status 422
        { error: "Erro ao criar usuário", details: user.errors.messages }.to_json
      end
      
    rescue => e
      status 500
      { error: "Erro ao criar usuário", message: e.message }.to_json
    end
  end

  # --- ATUALIZAR USUÁRIO ---
  put '/:id' do
    begin
      params_data = env['parsed_json'] || {}
      
      user = User.find(params[:id])
      
      # Validar acesso: admin só atualiza usuários da mesma empresa
      if @current_user_role == 'admin' && user.company_id.to_s != @current_company_id
        status 403
        return { error: 'Acesso negado' }.to_json
      end
      
      # Admin não pode mudar a própria role
      if user.id.to_s == @current_user_id && params_data['role']
        status 403
        return { error: 'Você não pode alterar sua própria role' }.to_json
      end
      
      # Atualizar campos permitidos
      allowed_fields = ['name', 'email', 'status', 'role', 'phone']
      update_data = params_data.select { |k, v| allowed_fields.include?(k) }
      
      # Se está mudando email, verificar se já existe
      if update_data['email'] && update_data['email'] != user.email
        if User.where(email: update_data['email']).exists?
          status 409
          return { error: "Email já cadastrado" }.to_json
        end
      end
      
      if user.update_attributes(update_data)
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
      else
        status 422
        { error: "Erro ao atualizar", details: user.errors.messages }.to_json
      end
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Usuário não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao atualizar usuário", message: e.message }.to_json
    end
  end

  # --- DELETAR USUÁRIO ---
  delete '/:id' do
    begin
      user = User.find(params[:id])
      
      # Apenas admin pode deletar
      unless @current_user_role == 'admin'
        status 403
        return { error: 'Apenas administradores podem deletar usuários' }.to_json
      end
      
      # Validar acesso: admin só deleta usuários da mesma empresa
      if user.company_id.to_s != @current_company_id
        status 403
        return { error: 'Acesso negado' }.to_json
      end
      
      # Não pode deletar a si mesmo
      if user.id.to_s == @current_user_id
        status 403
        return { error: 'Você não pode deletar sua própria conta' }.to_json
      end
      
      user.destroy
      
      status 200
      { status: 'success', message: 'Usuário deletado com sucesso' }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Usuário não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao deletar usuário", message: e.message }.to_json
    end
  end
end
