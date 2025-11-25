require 'bundler/setup'
Bundler.require
require_relative '../app/controllers/health_controller'
require_relative '../app/controllers/test_controller'

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
