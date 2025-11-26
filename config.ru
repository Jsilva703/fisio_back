# encoding: UTF-8
require 'bundler/setup'

# Carregar variáveis de ambiente do .env ANTES de Bundler.require
require 'dotenv'
Dotenv.load

Bundler.require

Time.zone = 'America/Sao_Paulo'

# 1. Carregar Configuração do Banco
Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

# 2. Middleware para parsear JSON
class JsonParserMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['CONTENT_TYPE']&.include?('application/json')
      begin
        body = env['rack.input'].read
        env['rack.input'] = StringIO.new(body)
        env['parsed_json'] = body.empty? ? {} : JSON.parse(body)
      rescue => e
        env['parsed_json'] = {}
      end
    else
      env['parsed_json'] = {}
    end
    @app.call(env)
  end
end

# 3. Carregar ficheiros
require_relative './app/models/appointment'
require_relative './app/controllers/appointments_controller'
require_relative './app/models/scheduling'
require_relative './app/controllers/schedulings_controller'
# require_relative './app/controllers/health_controller'

class App < Sinatra::Base
  configure do
    enable :logging
    set :show_exceptions, false
    
    # --- CORREÇÃO DO ERRO ---
    # Define o fuso horário padrão para evitar o erro 'nil.parse' no Mongoid
    Time.zone = 'America/Sao_Paulo'    # ------------------------
  end

  before do
    content_type :json
  end
  
  # ... resto das rotas ...
  get '/' do
    { status: 'API DJM Online', plataforma: 'Render 🚀' }.to_json
  end
  
  get '/health' do
    { status: 'OK', db: 'Connected' }.to_json
  end
end

use Rack::Cors do
  allow do
    origins '*' 
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
  end
end

use JsonParserMiddleware

map('/api/appointments') { run AppointmentsController }
map('/api/schedulings') { run SchedulingsController}
map('/') { run App }