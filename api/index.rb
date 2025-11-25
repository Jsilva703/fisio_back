begin
  require 'bundler/setup'
  Bundler.require(:default)
rescue LoadError => e
  puts "Warning: #{e.message}"
  # Fallback - carrega as gems sem Bundler
  require 'sinatra'
  require 'rack/cors'
end

class App < Sinatra::Base
  set :show_exceptions, false
  set :dump_errors, false

  # Rota raiz
  get '/' do
    content_type :json
    {
      status: 'success',
      message: 'Bem-vindo à API DJM!',
      endpoints: [
        { method: 'GET', path: '/', description: 'Raiz da API' },
        { method: 'GET', path: '/health', description: 'Status de saúde' },
        { method: 'GET', path: '/api/info', description: 'Informações da API' },
        { method: 'GET', path: '/api/test', description: 'Teste' }
      ]
    }.to_json
  end

  # Rota de saúde
  get '/health' do
    content_type :json
    {
      status: 'OK',
      message: 'API funcionando!',
      timestamp: Time.now.iso8601
    }.to_json
  end

  # Informações da API
  get '/api/info' do
    content_type :json
    {
      name: 'API DJM',
      version: '1.0.0',
      description: 'API para fisioterapia',
      environment: ENV['RACK_ENV'] || 'production'
    }.to_json
  end

  # Rota de teste
  get '/api/test' do
    content_type :json
    {
      status: 'success',
      message: 'Teste funcionando!',
      timestamp: Time.now.iso8601,
      random: rand(1..100)
    }.to_json
  end

  # 404
  not_found do
    content_type :json
    { status: 'error', message: 'Rota não encontrada' }.to_json
  end
end

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
  end
end

run App
