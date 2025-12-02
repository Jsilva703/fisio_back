require 'jwt'

class AuthMiddleware
  JWT_SECRET = ENV['JWT_SECRET'] || 'sua_chave_secreta_aqui_troque_em_producao'

  def initialize(app)
    @app = app
  end

  def call(env)
    request_path = env['PATH_INFO']

    # Rotas públicas que não precisam de autenticação
    public_paths = [
      '/health',
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth' # Permite todas as rotas de auth
    ]

    # Verifica se é a rota raiz exata
    if request_path == '/'
      return @app.call(env)
    end

    # Se a rota é pública, deixa passar
    if public_paths.any? { |path| request_path.start_with?(path) }
      return @app.call(env)
    end

    # Para rotas protegidas, valida o token
    auth_header = env['HTTP_AUTHORIZATION']

    if auth_header.nil?
      return unauthorized_response('Token não fornecido')
    end

    begin
      token = auth_header.split(' ').last
      decoded = JWT.decode(token, JWT_SECRET, true, { algorithm: 'HS256' })
      
      # Adiciona os dados do usuário ao env para uso nos controllers
      env['current_user_id'] = decoded[0]['user_id']
      env['current_user_email'] = decoded[0]['email']
      env['current_user_role'] = decoded[0]['role']

      @app.call(env)

    rescue JWT::ExpiredSignature
      unauthorized_response('Token expirado')
    rescue JWT::DecodeError
      unauthorized_response('Token inválido')
    rescue => e
      error_response("Erro na autenticação: #{e.message}")
    end
  end

  private

  def unauthorized_response(message)
    [
      401,
      { 'content-type' => 'application/json' },
      [{ error: message }.to_json]
    ]
  end

  def error_response(message)
    [
      500,
      { 'content-type' => 'application/json' },
      [{ error: message }.to_json]
    ]
  end
end
