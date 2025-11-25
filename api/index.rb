require 'bundler/setup'
Bundler.require

# Health Controller
class HealthController
  def self.check
    {
      status: 'OK',
      message: 'API DJM está funcionando perfeitamente!',
      timestamp: Time.now.iso8601,
      environment: ENV['RACK_ENV'] || 'production'
    }
  end

  def self.info
    {
      name: 'API DJM',
      version: '1.0.0',
      description: 'API para gerenciamento de fisioterapia',
      uptime: 'Sistema em operação',
      created_at: '2025-11-25'
    }
  end
end

# Test Controller
class TestController
  def self.welcome
    {
      status: 'success',
      message: 'Bem-vindo à API DJM!',
      data: {
        welcome_text: 'Esta é uma API de teste para fisioterapia',
        endpoints: [
          { method: 'GET', path: '/', description: 'Raiz da API' },
          { method: 'GET', path: '/health', description: 'Status de saúde da API' },
          { method: 'GET', path: '/api/info', description: 'Informações da API' },
          { method: 'GET', path: '/api/test', description: 'Rota de teste' }
        ]
      }
    }
  end

  def self.test_message
    {
      status: 'success',
      message: 'Teste de rota funcionando!',
      data: {
        timestamp: Time.now.iso8601,
        random_number: rand(1..100),
        test_array: ['item1', 'item2', 'item3']
      }
    }
  end
end

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
  end
end

class App < Sinatra::Base
  set :json_encoder, :to_json

  # Rota raiz
  get '/' do
    content_type :json
    TestController.welcome.to_json
  end

  # Rota de saúde da API
  get '/health' do
    content_type :json
    HealthController.check.to_json
  end

  # Informações da API
  get '/api/info' do
    content_type :json
    HealthController.info.to_json
  end

  # Rota de teste
  get '/api/test' do
    content_type :json
    TestController.test_message.to_json
  end

  # Rota 404
  not_found do
    content_type :json
    {
      status: 'error',
      message: 'Rota não encontrada',
      path: request.path
    }.to_json
  end

  # Tratamento de erros
  error do
    content_type :json
    {
      status: 'error',
      message: 'Erro interno do servidor',
      error: env['sinatra.error'].message
    }.to_json
  end
end

run App
