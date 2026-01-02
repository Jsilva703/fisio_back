# frozen_string_literal: true

module Companies
  class CompaniesController < Sinatra::Base
    configure do
      enable :logging
      set :method_override, true # Permite PUT/DELETE via _method
    end

    before do
      content_type :json

      # Apenas usuários com role 'machine' podem acessar
      if env['current_user_role'] != 'machine'
        halt 403, { error: 'Acesso negado. Esta rota é exclusiva para machines.' }.to_json
      end
    end

    # --- LISTAR TODAS AS EMPRESAS ---
    get '/' do
      companies = Companies::CompaniesService.list_all

      companies_data = companies.map do |company|
        {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug,
          email: company.email,
          phone: company.phone,
          cnpj: company.cnpj,
          plan: company.plan,
          status: company.status,
          max_users: company.max_users,
          users_count: company.users_count,
          appointments_count: company.appointments_count,
          schedulings_count: company.schedulings_count,
          created_at: company.created_at,
          updated_at: company.updated_at
        }
      end

      status 200
      {
        status: 'success',
        total: companies.count,
        companies: companies_data
      }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao listar empresas', mensagem: e.message }.to_json
    end

    # --- BUSCAR EMPRESA POR ID ---
    get '/:id' do
      company = Companies::CompaniesService.find(params[:id])

      status 200
      {
        status: 'success',
        company: {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug,
          email: company.email,
          phone: company.phone,
          cnpj: company.cnpj,
          address: company.address,
          plan: company.plan,
          status: company.status,
          max_users: company.max_users,
          settings: company.settings,
          users_count: company.users_count,
          appointments_count: company.appointments_count,
          schedulings_count: company.schedulings_count,
          created_at: company.created_at,
          updated_at: company.updated_at
        }
      }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Empresa não encontrada' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar empresa', mensagem: e.message }.to_json
    end

    # --- CRIAR EMPRESA ---
    post '/' do
      params_data = env['parsed_json'] || {}

      if params_data.empty? || !params_data['name'] || !params_data['email']
        status 400
        return { error: 'Nome e email são obrigatórios' }.to_json
      end

      company = Companies::CompaniesService.create(params_data)

      status 201
      { status: 'success', message: 'Empresa criada com sucesso', company: company }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    # --- ATUALIZAR EMPRESA (PUT completo) ---
    put '/:id' do
      params_data = env['parsed_json'] || {}

      if params_data.empty?
        status 400
        return { error: 'Nenhum dado enviado para atualização' }.to_json
      end

      company = Companies::CompaniesService.update(params[:id], params_data)

      status 200
      {
        status: 'success',
        message: 'Empresa atualizada com sucesso',
        company: {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug,
          email: company.email,
          phone: company.phone,
          cnpj: company.cnpj,
          address: company.address,
          plan: company.plan,
          status: company.status,
          max_users: company.max_users,
          billing_day: company.billing_day,
          billing_due_date: company.billing_due_date,
          payment_status: company.payment_status,
          settings: company.settings,
          updated_at: company.updated_at
        }
      }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Empresa não encontrada' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao atualizar empresa', mensagem: e.message }.to_json
    end

    # --- ATUALIZAR EMPRESA (PATCH parcial - mantido para compatibilidade) ---
    patch '/:id' do
      # Redireciona para PUT
      call env.merge('REQUEST_METHOD' => 'PUT')
    end

    # --- DELETAR EMPRESA ---
    delete '/:id' do
      Companies::CompaniesService.delete(params[:id])

      status 200
      { status: 'success', message: 'Empresa deletada com sucesso' }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Empresa não encontrada' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao deletar empresa', mensagem: e.message }.to_json
    end

    # --- ESTATÍSTICAS DA EMPRESA ---
    get '/:id/stats' do
      result = Companies::CompaniesService.stats(params[:id])

      status 200
      result.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Empresa não encontrada' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar estatísticas', mensagem: e.message }.to_json
    end
  end
end
