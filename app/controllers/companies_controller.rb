class CompaniesController < Sinatra::Base
  configure do
    enable :logging
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
    begin
      companies = Company.all.order_by(created_at: :desc)
      
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
      
    rescue => e
      status 500
      { error: "Erro ao listar empresas", mensagem: e.message }.to_json
    end
  end

  # --- BUSCAR EMPRESA POR ID ---
  get '/:id' do
    begin
      company = Company.find(params[:id])
      
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
      { error: "Empresa não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar empresa", mensagem: e.message }.to_json
    end
  end

  # --- CRIAR EMPRESA ---
  post '/' do
    begin
      params_data = env['parsed_json'] || {}
      
      if params_data.empty? || !params_data['name'] || !params_data['email']
        status 400
        return { error: "Nome e email são obrigatórios" }.to_json
      end

      company = Company.new(
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        cnpj: params_data['cnpj'],
        address: params_data['address'],
        plan: params_data['plan'] || 'basic',
        max_users: params_data['max_users'] || 5,
        settings: params_data['settings'] || {}
      )

      if company.save
        status 201
        {
          status: 'success',
          message: 'Empresa criada com sucesso',
          company: company
        }.to_json
      else
        status 422
        { error: "Erro ao criar empresa", detalhes: company.errors.messages }.to_json
      end

    rescue => e
      status 500
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- ATUALIZAR EMPRESA ---
  patch '/:id' do
    begin
      params_data = env['parsed_json'] || {}
      company = Company.find(params[:id])
      
      # Atualiza apenas os campos permitidos
      allowed_fields = ['name', 'email', 'phone', 'cnpj', 'address', 'plan', 'status', 'max_users', 'settings']
      update_data = params_data.select { |k, v| allowed_fields.include?(k) }
      
      company.update(update_data) unless update_data.empty?
      
      status 200
      {
        status: 'success',
        message: 'Empresa atualizada com sucesso',
        company: company
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Empresa não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro ao atualizar empresa", mensagem: e.message }.to_json
    end
  end

  # --- DELETAR EMPRESA ---
  delete '/:id' do
    begin
      company = Company.find(params[:id])
      
      # Verificar se a empresa tem dados associados
      if company.users.exists? || company.appointments.exists? || company.schedulings.exists?
        status 409
        return {
          error: "Não é possível deletar empresa com dados associados",
          users_count: company.users_count,
          appointments_count: company.appointments_count,
          schedulings_count: company.schedulings_count
        }.to_json
      end
      
      company.delete
      
      status 200
      { status: 'success', message: 'Empresa deletada com sucesso' }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Empresa não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro ao deletar empresa", mensagem: e.message }.to_json
    end
  end

  # --- ESTATÍSTICAS DA EMPRESA ---
  get '/:id/stats' do
    begin
      company = Company.find(params[:id])
      
      # Buscar usuários da empresa
      users = company.users.to_a
      
      # Buscar agendamentos da empresa
      appointments = company.appointments.to_a
      
      # Calcular estatísticas
      total_revenue = appointments.sum { |a| a.price.to_f }
      appointments_by_status = appointments.group_by(&:status).transform_values(&:count)
      appointments_by_payment = appointments.group_by(&:payment_status).transform_values(&:count)
      
      status 200
      {
        status: 'success',
        company_id: company.id.to_s,
        company_name: company.name,
        stats: {
          users: {
            total: users.count,
            max_allowed: company.max_users,
            by_role: users.group_by(&:role).transform_values(&:count)
          },
          appointments: {
            total: appointments.count,
            by_status: appointments_by_status,
            by_payment: appointments_by_payment,
            total_revenue: total_revenue
          },
          schedulings: {
            total: company.schedulings_count
          }
        }
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Empresa não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar estatísticas", mensagem: e.message }.to_json
    end
  end
end
