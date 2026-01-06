# frozen_string_literal: true

require 'jwt'

class AuthMiddleware
  JWT_SECRET = ENV['JWT_SECRET'] || 'sua_chave_secreta_aqui_troque_em_producao'

  def initialize(app)
    @app = app
  end

  def call(env)
    request_path = env['PATH_INFO']

    # Verifica se é a rota raiz exata
    return @app.call(env) if request_path == '/'

    # Rotas públicas que não precisam de autenticação
    public_paths = [
      '/health',
      '/api/public/booking', # Agendamento online público (deve vir ANTES de /api/auth)
      '/api/public',
      '/api/machine/companies/stream', # SSE público para novas empresas
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth' # Permite todas as rotas de auth
    ]

    # Se a rota é pública, deixa passar
    return @app.call(env) if public_paths.any? { |path| request_path.start_with?(path) }

    # Para rotas protegidas, valida o token
    auth_header = env['HTTP_AUTHORIZATION']

    return unauthorized_response('Token não fornecido') if auth_header.nil?

    begin
      token = auth_header.split(' ').last
      decoded = JWT.decode(token, JWT_SECRET, true, { algorithm: 'HS256' })

      # Adiciona os dados do usuário ao env para uso nos controllers
      env['current_user_id'] = decoded[0]['user_id']
      env['current_user_email'] = decoded[0]['email']
      env['current_user_role'] = decoded[0]['role']
      env['current_company_id'] = decoded[0]['company_id'] # IMPORTANTE: company_id do token

      # Bloquear role 'machine' de acessar rotas da clínica
      clinic_routes = ['/api/appointments', '/api/schedulings']
      user_role = decoded[0]['role']

      if user_role == 'machine' && clinic_routes.any? { |route| request_path.start_with?(route) }
        return forbidden_response('Acesso negado. Usuários do tipo machine não podem acessar dados da clínica.')
      end

      # Verificar se usuários normais têm company_id (exceto machine)
      if user_role != 'machine' && decoded[0]['company_id'].nil?
        return forbidden_response('Usuário sem empresa associada.')
      end

      # Verificar se a empresa está com pagamento em dia (exceto para machine)
      if user_role != 'machine' && decoded[0]['company_id']
        require_relative '../models/company'
        company = Company.find(decoded[0]['company_id'])

        # If company is on trial and trial active, allow access
        if company
          if company.status == 'pending'
            return [
              403,
              { 'content-type' => 'application/json' },
              [{ error: 'Empresa pendente. Acesso restrito até ativação.' }.to_json]
            ]
          end

          if company.payment_overdue?
            return [
              403,
              { 'content-type' => 'application/json' },
              [{
                error: 'Pagamento em atraso. Acesso suspenso.',
                payment_status: company.payment_status,
                billing_due_date: company.billing_due_date
              }.to_json]
            ]
          end

          # Plan-based access control: define minimal plan required per route
          route_min_plan = {
            '/api/medical_records' => 'standard',
            '/api/professionals' => 'basic',
            '/api/rooms' => 'basic',
            '/api/appointments' => 'basic',
            '/api/schedulings' => 'basic'
          }

          # Load ordered plans from config to compare rank
          begin
            require 'yaml'
            plans_cfg = YAML.load_file(File.join(File.dirname(__FILE__), '..', '..', 'config', 'plans.yml'))['plans'] rescue nil
            plan_order = plans_cfg ? plans_cfg.keys : %w[free basic standard premium enterprise professional]
          rescue StandardError
            plan_order = %w[free basic standard premium enterprise professional]
          end

          route_min_plan.each do |route, min_plan|
            if request_path.start_with?(route)
              company_plan_index = plan_order.index(company.plan) || 0
              min_plan_index = plan_order.index(min_plan) || 0
              if company_plan_index < min_plan_index && !(company.on_trial && company.trial_ends_at && Date.today <= company.trial_ends_at)
                return [
                  403,
                  { 'content-type' => 'application/json' },
                  [{ error: 'Plano insuficiente para acessar este recurso', required_plan: min_plan, current_plan: company.plan }.to_json]
                ]
              end
            end
          end
        end
      end

      @app.call(env)
    rescue JWT::ExpiredSignature
      unauthorized_response('Token expirado')
    rescue JWT::DecodeError
      unauthorized_response('Token inválido')
    rescue StandardError => e
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

  def forbidden_response(message)
    [
      403,
      { 'content-type' => 'application/json' },
      [{ error: message }.to_json]
    ]
  end
end
