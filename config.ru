# frozen_string_literal: true

require 'bundler/setup'

# Carregar variáveis de ambiente do .env ANTES de Bundler.require
require 'dotenv'
Dotenv.load

Bundler.require

require 'active_support/time'
# Ensure Time.zone is a TimeZone object
Time.zone = ActiveSupport::TimeZone['America/Sao_Paulo']

# 1. Carregar Configuração do Banco
Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

# 1.1. Carregar Initializers (antes dos services)
Dir[File.join(File.dirname(__FILE__), 'config', 'initializers', '*.rb')].sort.each do |f|
  require File.expand_path(f)
end

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
require_relative './app/controllers/machine/companies_stream_controller'
require_relative './app/controllers/machine/company_requests_controller'
require_relative './app/controllers/billing/billing_controller'
require_relative './app/controllers/billing/checkout_controller'
require_relative './app/controllers/patients/patients_controller'
require_relative './app/controllers/professionals/professionals_controller'
require_relative './app/controllers/rooms/rooms_controller'
require_relative './app/controllers/medical_records/medical_records_controller'
require_relative './app/controllers/public_booking/public_booking_controller'
require_relative './app/controllers/users/users_controller'
require_relative './app/middleware/auth_middleware'
require_relative './app/controllers/admin/users_controller'
require_relative './app/controllers/public/signup_company_controller'
require_relative './app/controllers/public/company_requests_controller'
# expenses files
require_relative './app/models/expense'
require_relative './app/controllers/expenses/expenses_controller'
# avatars controller
require_relative './app/controllers/avatars/avatars_controller'
# require_relative './app/controllers/health_controller'

# Load service objects
Dir[File.join(File.dirname(__FILE__), 'app', 'services', '**', '*.rb')].sort.each do |f|
  require File.expand_path(f)
end

# NOTE: Rack::Attack will be loaded after CORS to ensure preflight requests
# are handled by Rack::Cors before any throttling/blocking.

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

# Configurable CORS: set APP_FRONT_URL to the frontend origin (or leave blank to allow any)
front_origin = ENV['APP_FRONT_URL'] || '*'
allow_credentials = ENV['CORS_ALLOW_CREDENTIALS'] == 'true'

use Rack::Cors do
  allow do
    origins front_origin
    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options],
             credentials: allow_credentials,
             expose: ['Authorization']
  end
end

 # Load Rack::Attack after CORS so preflight OPTIONS are not blocked
begin
  require_relative './config/initializers/rack_attack'
  use Rack::Attack
rescue LoadError
  # if not present, continue without it
end

use JsonParserMiddleware
use AuthMiddleware
# Avatars routes (precisa ficar antes do map)
use Avatars::AvatarsController

map('/api/auth') { run Auth::AuthController }
map('/api/machine') { run Machine::MachineController }
map('/api/machine/companies') { run Machine::CompaniesStreamController }
map('/api/machine/company_requests') { run Machine::CompanyRequestsController }
map('/api/companies') { run Companies::CompaniesController }
map('/api/billing') { run Billing::BillingController }
map('/api/billing/checkout') { run Billing::CheckoutController }
map('/api/patients') { run Patients::PatientsController }
map('/api/medical-records') { run MedicalRecords::MedicalRecordsController }
map('/api/users') { run Users::UsersController }
map('/api/public/booking') { run PublicBooking::PublicBookingController }
map('/api/appointments') { run Appointments::AppointmentsController }
map('/api/schedulings') { run Schedulings::SchedulingsController }
map('/api/professionals') { run Professionals::ProfessionalsController }
map('/api/rooms') { run Rooms::RoomsController }
map('/api/expenses') { run Expenses::ExpensesController }
map('/api/admin/users') { run Admin::UsersController }
map('/api/public/signup_company') { run Public::SignupCompanyController }
map('/api/public/company_requests') { run Public::CompanyRequestsController }
map('/') { run App }
