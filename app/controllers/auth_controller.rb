require 'jwt'

class AuthController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
  end

  # Chave secreta para JWT (coloque no .env em produção)
  JWT_SECRET = ENV['JWT_SECRET'] || 'sua_chave_secreta_aqui_troque_em_producao'

  # --- REGISTRO DE USUÁRIO ---
  post '/register' do
    begin
      params_data = env['parsed_json'] || {}
      
      if params_data.empty? || !params_data['email'] || !params_data['password']
        status 400
        return { error: "Email e senha são obrigatórios" }.to_json
      end

      # Verifica se o usuário já existe
      if User.where(email: params_data['email']).exists?
        status 409
        return { error: "Email já cadastrado" }.to_json
      end

      # Verificar company_id (obrigatório para users/admins, opcional para machine)
      role = params_data['role'] || 'user'
      if role != 'machine' && !params_data['company_id']
        status 400
        return { error: "company_id é obrigatório para usuários que não são machine" }.to_json
      end

      # Verificar se a empresa existe e está ativa
      if role != 'machine'
        company = Company.find(params_data['company_id'])
        
        unless company.active?
          status 403
          return { error: "Empresa inativa ou suspensa" }.to_json
        end
        
        unless company.can_add_user?
          status 403
          return { error: "Limite de usuários atingido para esta empresa" }.to_json
        end
      end

      # Cria o usuário
      user = User.new(
        name: params_data['name'],
        email: params_data['email'],
        role: role,
        company_id: role == 'machine' ? nil : params_data['company_id']
      )
      user.password = params_data['password']

      if user.save
        # Gera token JWT
        token = generate_token(user)
        
        status 201
        return { 
          status: 'success', 
          message: 'Usuário criado com sucesso',
          token: token,
          user: user
        }.to_json
      else
        status 422
        return { error: "Erro ao criar usuário", detalhes: user.errors.messages }.to_json
      end

    rescue => e
      status 500
      return { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- LOGIN ---
  post '/login' do
    begin
      params_data = env['parsed_json'] || {}
      
      if params_data.empty? || !params_data['email'] || !params_data['password']
        status 400
        return { error: "Email e senha são obrigatórios" }.to_json
      end

      # Busca o usuário pelo email
      user = User.find_by(email: params_data['email'])
      
      if user.nil?
        status 401
        return { error: "Email ou senha inválidos" }.to_json
      end

      # Verificar se a empresa está ativa (exceto para machine)
      if user.role != 'machine' && user.company
        unless user.company.active?
          status 403
          return { error: "Empresa inativa ou suspensa" }.to_json
        end
      end

      # Verifica a senha
      if user.authenticate(params_data['password'])
        # Gera token JWT
        token = generate_token(user)
        
        status 200
        return { 
          status: 'success',
          message: 'Login realizado com sucesso',
          token: token,
          user: user
        }.to_json
      else
        status 401
        return { error: "Email ou senha inválidos" }.to_json
      end

    rescue => e
      status 500
      return { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- OBTER USUÁRIO ATUAL (requer autenticação) ---
  get '/me' do
    begin
      # Obtém o token do header Authorization
      auth_header = request.env['HTTP_AUTHORIZATION']
      
      if auth_header.nil?
        status 401
        return { error: "Token não fornecido" }.to_json
      end

      token = auth_header.split(' ').last
      
      # Decodifica o token
      decoded = JWT.decode(token, JWT_SECRET, true, { algorithm: 'HS256' })
      user_id = decoded[0]['user_id']
      
      # Busca o usuário
      user = User.find(user_id)
      
      status 200
      return { status: 'success', user: user }.to_json

    rescue JWT::DecodeError
      status 401
      return { error: "Token inválido" }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      return { error: "Usuário não encontrado" }.to_json
    rescue => e
      status 500
      return { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- MÉTODO AUXILIAR PARA GERAR TOKEN ---
  private
  
  def generate_token(user)
    payload = {
      user_id: user.id.to_s,
      email: user.email,
      role: user.role,
      company_id: user.company_id&.to_s,
      exp: Time.now.to_i + (24 * 3600) # Expira em 24 horas
    }
    JWT.encode(payload, JWT_SECRET, 'HS256')
  end
end
