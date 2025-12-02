class MachineController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
    
    # Verificar se o usuário é do tipo machine
    if env['current_user_role'] != 'machine'
      halt 403, { error: 'Acesso negado. Esta rota é exclusiva para machines.' }.to_json
    end
  end

  # --- DASHBOARD PARA MACHINES ---
  get '/dashboard' do
    begin
      user_id = env['current_user_id']
      
      # Estatísticas globais do SaaS
      total_companies = Company.count
      active_companies = Company.where(status: 'active').count
      inactive_companies = Company.where(status: 'inactive').count
      suspended_companies = Company.where(status: 'suspended').count
      
      total_users = User.where(:company_id.ne => nil).count
      total_appointments = Appointment.count
      total_schedulings = Scheduling.count
      
      # Receita total (soma de todos appointments)
      total_revenue = Appointment.all.sum { |a| a.price.to_f }
      
      # Empresas por plano
      companies_by_plan = Company.all.group_by(&:plan).transform_values(&:count)
      
      # Top 5 empresas com mais agendamentos
      top_companies = Company.all.map do |company|
        {
          id: company.id.to_s,
          name: company.name,
          plan: company.plan,
          appointments_count: company.appointments_count,
          users_count: company.users_count,
          total_revenue: company.appointments.sum { |a| a.price.to_f }
        }
      end.sort_by { |c| -c[:appointments_count] }.take(5)
      
      status 200
      {
        status: 'success',
        message: 'Dashboard Machine - SaaS Overview',
        user_id: user_id,
        timestamp: Time.now,
        overview: {
          companies: {
            total: total_companies,
            active: active_companies,
            inactive: inactive_companies,
            suspended: suspended_companies,
            by_plan: companies_by_plan
          },
          users: {
            total: total_users
          },
          appointments: {
            total: total_appointments,
            total_revenue: total_revenue.round(2)
          },
          schedulings: {
            total: total_schedulings
          }
        },
        top_companies: top_companies
      }.to_json
      
    rescue => e
      status 500
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- EXEMPLO: ENDPOINT PARA MACHINE ENVIAR DADOS ---
  post '/sync' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Processar dados enviados pela machine
      # Exemplo: salvar logs, métricas, etc.
      
      status 200
      {
        status: 'success',
        message: 'Dados sincronizados com sucesso',
        timestamp: Time.now
      }.to_json
      
    rescue => e
      status 500
      { error: "Erro ao sincronizar", mensagem: e.message }.to_json
    end
  end

  # --- EXEMPLO: CONFIGURAÇÕES DA MACHINE ---
  get '/config' do
    begin
      # Retornar configurações específicas para esta machine
      status 200
      {
        status: 'success',
        config: {
          version: '1.0.0',
          endpoints: {
            sync: '/api/machine/sync',
            dashboard: '/api/machine/dashboard'
          },
          settings: {
            # Suas configurações aqui
          }
        }
      }.to_json
      
    rescue => e
      status 500
      { error: "Erro ao buscar configurações", mensagem: e.message }.to_json
    end
  end
end
