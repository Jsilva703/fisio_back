# frozen_string_literal: true

module Machine
  class MachineController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json
      if env['current_user_role'] != 'machine'
        halt 403, { error: 'Acesso negado. Esta rota é exclusiva para machines.' }.to_json
      end
    end

    # --- DASHBOARD PARA MACHINES ---
    get '/dashboard' do
      user_id = env['current_user_id']
      stats = Machine::MachineDashboardService.dashboard_stats
      status 200
      {
        status: 'success',
        message: 'Dashboard Machine - SaaS Overview',
        user_id: user_id,
        timestamp: Time.now,
        overview: {
          companies: {
            total: stats[:total_companies],
            active: stats[:active_companies],
            inactive: stats[:inactive_companies],
            suspended: stats[:suspended_companies],
            by_plan: stats[:companies_by_plan]
          },
          users: {
            total: stats[:total_users]
          },
          appointments: {
            total: stats[:total_appointments],
            total_revenue: stats[:total_revenue].round(2)
          },
          schedulings: {
            total: stats[:total_schedulings]
          }
        },
        top_companies: stats[:top_companies]
      }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    # --- EXEMPLO: ENDPOINT PARA MACHINE ENVIAR DADOS ---
    post '/sync' do
      env['parsed_json'] || {}
      status 200
      {
        status: 'success',
        message: 'Dados sincronizados com sucesso',
        timestamp: Time.now
      }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao sincronizar', mensagem: e.message }.to_json
    end

    # --- EXEMPLO: CONFIGURAÇÕES DA MACHINE ---
    get '/config' do
      status 200
      {
        status: 'success',
        config: {
          version: '1.0.0',
          endpoints: {
            sync: '/api/machine/sync',
            dashboard: '/api/machine/dashboard'
          },
          settings: {}
        }
      }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar configurações', mensagem: e.message }.to_json
    end
  end
end
