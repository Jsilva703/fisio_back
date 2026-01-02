# frozen_string_literal: true

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
      rescue StandardError
        env['parsed_json'] = {}
      end
    else
      env['parsed_json'] = {}
    end
    @app.call(env)
  end
end

# 3. Carregar ficheiros
require_relative './app/models/company'
require_relative './app/models/appointment'
require_relative './app/controllers/appointments/appointments_controller'
require_relative './app/models/scheduling'
require_relative './app/controllers/schedulings/schedulings_controller'
require_relative './app/models/user'
require_relative './app/models/patient'
require_relative './app/models/professional'
require_relative './app/models/room'
require_relative './app/models/medical_record'
require_relative './app/controllers/auth/auth_controller'
require_relative './app/controllers/machine/machine_controller'
require_relative './app/controllers/companies/companies_controller'
require_relative './app/controllers/billing/billing_controller'
require_relative './app/controllers/patients/patients_controller'
require_relative './app/controllers/professionals/professionals_controller'
require_relative './app/controllers/rooms/rooms_controller'
require_relative './app/controllers/medical_records/medical_records_controller'
require_relative './app/controllers/public_booking/public_booking_controller'
require_relative './app/controllers/users/users_controller'
require_relative './app/middleware/auth_middleware'
# require_relative './app/controllers/health_controller'

# Load service objects
Dir[File.join(File.dirname(__FILE__), 'app', 'services', '**', '*.rb')].sort.each do |f|
  require File.expand_path(f)
end

# Load security middlewares (Rack::Attack)
begin
  require_relative './config/initializers/rack_attack'
  use Rack::Attack
rescue LoadError
  # if not present, continue without it
end

class App < Sinatra::Base
  configure do
    enable :logging
    set :show_exceptions, false

    # --- CORREÇÃO DO ERRO ---
    # Define o fuso horário padrão para evitar o erro 'nil.parse' no Mongoid
    Time.zone = 'America/Sao_Paulo' # ------------------------
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
    resource '*', headers: :any, methods: %i[get post put patch delete options]
  end
end

use JsonParserMiddleware
use AuthMiddleware

map('/api/auth') { run Auth::AuthController }
map('/api/machine') { run Machine::MachineController }
map('/api/companies') { run Companies::CompaniesController }
map('/api/billing') { run Billing::BillingController }
map('/api/patients') { run Patients::PatientsController }
map('/api/medical-records') { run MedicalRecords::MedicalRecordsController }
map('/api/users') { run Users::UsersController }
map('/api/public/booking') { run PublicBooking::PublicBookingController }
map('/api/appointments') { run Appointments::AppointmentsController }
map('/api/schedulings') { run Schedulings::SchedulingsController }
map('/api/professionals') { run Professionals::ProfessionalsController }
map('/api/rooms') { run Rooms::RoomsController }
map('/') { run App }
