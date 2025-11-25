# encoding: UTF-8
require 'bundler/setup'
Bundler.require

class APIApp < Sinatra::Base
  configure do
    disable :protection
    set :bind, '0.0.0.0'
    set :port, ENV['PORT'] || 3000
  end

  use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
    end
  end

  get '/' do
    content_type :json
    {
      status: 'success',
      message: 'Bem-vindo à API DJM!',
      environment: ENV['RACK_ENV'] || 'development',
      timestamp: Time.now.iso8601
    }.to_json
  end

  get '/health' do
    content_type :json
    {
      status: 'healthy',
      message: 'API está funcionando!',
      timestamp: Time.now.iso8601,
      uptime: 'online'
    }.to_json
  end

  get '/api/info' do
    content_type :json
    {
      name: 'API DJM',
      version: '1.0.0',
      description: 'API para gerenciamento de fisioterapia',
      author: 'DJM Team',
      environment: ENV['RACK_ENV'] || 'development'
    }.to_json
  end

  get '/api/test' do
    content_type :json
    {
      status: 'success',
      message: 'Teste de rota funcionando!',
      timestamp: Time.now.iso8601,
      random_number: rand(1..100),
      endpoints: [
        { method: 'GET', path: '/', description: 'Raiz da API' },
        { method: 'GET', path: '/health', description: 'Status de saúde' },
        { method: 'GET', path: '/api/info', description: 'Informações' },
        { method: 'GET', path: '/api/test', description: 'Teste' }
      ]
    }.to_json
  end

  not_found do
    content_type :json
    { status: 'error', message: 'Rota não encontrada', path: request.path }.to_json
  end

  error do
    content_type :json
    { status: 'error', message: 'Erro interno do servidor' }.to_json
  end
end

run APIApp
