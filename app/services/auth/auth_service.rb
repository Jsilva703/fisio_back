# frozen_string_literal: true

# Serviços relacionados a autenticação (login/register, tokens)
require 'jwt'

module Auth
  class AuthService
    JWT_SECRET = ENV['JWT_SECRET']

    def self.register(params)
      if params.nil? || !params['email'] || !params['password']
        return { status: 400,
                 body: { error: 'Email e senha são obrigatórios' } }
      end

      return { status: 409, body: { error: 'Email já cadastrado' } } if User.where(email: params['email']).exists?

      role = params['role'] || 'user'
      if role != 'machine' && !params['company_id']
        return { status: 400, body: { error: 'company_id é obrigatório para usuários que não são machine' } }
      end

      if role != 'machine'
        company = Company.find(params['company_id'])
        return { status: 403, body: { error: 'Empresa inativa ou suspensa' } } unless company&.active?

        unless company.can_add_user?
          return { status: 403,
                   body: { error: 'Limite de usuários atingido para esta empresa' } }
        end
      end

      user = User.new(
        name: params['name'],
        email: params['email'],
        role: role,
        company_id: role == 'machine' ? nil : params['company_id']
      )
      user.password = params['password']

      if user.save
        token = generate_token(user)
        { status: 201, body: { status: 'success', message: 'Usuário criado com sucesso', token: token, user: user } }
      else
        { status: 422, body: { error: 'Erro ao criar usuário', detalhes: user.errors.messages } }
      end
    rescue StandardError => e
      { status: 500, body: { error: 'Erro interno', mensagem: e.message } }
    end

    def self.login(params)
      if params.nil? || !params['email'] || !params['password']
        return { status: 400,
                 body: { error: 'Email e senha são obrigatórios' } }
      end

      user = User.find_by(email: params['email'])
      return { status: 401, body: { error: 'Email ou senha inválidos' } } if user.nil?

      if user.role != 'machine' && user.company && !user.company.active?
        return { status: 403, body: { error: 'Empresa inativa ou suspensa' } }
      end

      if user.authenticate(params['password'])
        token = generate_token(user)
        { status: 200, body: { status: 'success', message: 'Login realizado com sucesso', token: token, user: user } }
      else
        { status: 401, body: { error: 'Email ou senha inválidos' } }
      end
    rescue StandardError => e
      { status: 500, body: { error: 'Erro interno', mensagem: e.message } }
    end

    def self.me(token)
      return { status: 401, body: { error: 'Token não fornecido' } } if token.nil?

      decoded = JWT.decode(token, JWT_SECRET, true, { algorithm: 'HS256' })
      user_id = decoded[0]['user_id']
      user = User.find(user_id)
      { status: 200, body: { status: 'success', user: user } }
    rescue JWT::DecodeError
      { status: 401, body: { error: 'Token inválido' } }
    rescue Mongoid::Errors::DocumentNotFound
      { status: 404, body: { error: 'Usuário não encontrado' } }
    rescue StandardError => e
      { status: 500, body: { error: 'Erro interno', mensagem: e.message } }
    end

    def self.generate_token(user)
      payload = {
        user_id: user.id.to_s,
        email: user.email,
        role: user.role,
        company_id: user.company_id&.to_s,
        exp: Time.now.to_i + (24 * 3600)
      }
      JWT.encode(payload, JWT_SECRET, 'HS256')
    end
  end
end
