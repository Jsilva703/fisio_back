require 'bundler/setup'
Bundler.require
require 'json'

class APIApp
  RESPONSE_HEADERS = { 'Content-Type' => 'application/json' }.freeze

  def call(env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']

    case [method, path]
    when ['GET', '/']
      response_json(200, {
        status: 'success',
        message: 'Bem-vindo à API DJM!',
        endpoints: [
          { method: 'GET', path: '/', description: 'Raiz da API' },
          { method: 'GET', path: '/health', description: 'Status de saúde' },
          { method: 'GET', path: '/api/info', description: 'Informações da API' },
          { method: 'GET', path: '/api/test', description: 'Teste' }
        ]
      })
    when ['GET', '/health']
      response_json(200, {
        status: 'OK',
        message: 'API funcionando!',
        timestamp: Time.now.iso8601
      })
    when ['GET', '/api/info']
      response_json(200, {
        name: 'API DJM',
        version: '1.0.0',
        description: 'API para fisioterapia',
        environment: ENV['RACK_ENV'] || 'production'
      })
    when ['GET', '/api/test']
      response_json(200, {
        status: 'success',
        message: 'Teste funcionando!',
        timestamp: Time.now.iso8601,
        random: rand(1..100)
      })
    else
      response_json(404, {
        status: 'error',
        message: 'Rota não encontrada',
        path: path
      })
    end
  end

  private

  def response_json(status, data)
    body = JSON.generate(data)
    [status, RESPONSE_HEADERS, [body]]
  end
end

class CorsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['REQUEST_METHOD'] == 'OPTIONS'
      return cors_response
    end
    
    status, headers, body = @app.call(env)
    
    headers.merge!(
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers' => '*'
    )
    
    [status, headers, body]
  end

  private

  def cors_response
    [200, cors_headers, ['OK']]
  end

  def cors_headers
    {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
      'Access-Control-Allow-Headers' => '*',
      'Content-Type' => 'text/plain'
    }
  end
end

app = APIApp.new
app = CorsMiddleware.new(app)

run app
