class ProfessionalsController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
    
    if request.content_type&.include?('application/json') && request.body.read.length > 0
      request.body.rewind
      env['parsed_json'] = JSON.parse(request.body.read)
    end
  end

  # --- LISTAR PROFISSIONAIS ---
  get '/' do
    begin
      company_id = env['current_company_id']
      
      profissionais = Professional.where(company_id: company_id)
      
      # Filtros opcionais
      if params[:status]
        profissionais = profissionais.where(status: params[:status])
      end
      
      if params[:search]
        profissionais = profissionais.where(
          :name => /#{Regexp.escape(params[:search])}/i
        )
      end
      
      profissionais = profissionais.order_by(professional_id: :asc)
      
      { status: 'success', profissionais: profissionais }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar profissionais", mensagem: e.message }.to_json
    end
  end

  # --- BUSCAR PROFISSIONAL POR ID ---
  get '/:id' do
    begin
      company_id = env['current_company_id']
      
      profissional = Professional.find_by(
        company_id: company_id,
        professional_id: params[:id].to_i
      )
      
      unless profissional
        status 404
        return { error: 'Profissional não encontrado' }.to_json
      end
      
      { status: 'success', profissional: profissional }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar profissional", mensagem: e.message }.to_json
    end
  end

  # --- CRIAR PROFISSIONAL ---
  post '/' do
    begin
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']
      
      if params_data.empty?
        status 400
        return { error: "Dados inválidos" }.to_json
      end
      
      profissional = Professional.new(
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        cpf: params_data['cpf'],
        registration_number: params_data['registration_number'],
        specialty: params_data['specialty'],
        color: params_data['color'] || '#3B82F6',
        company_id: company_id
      )
      
      if profissional.save
        status 201
        { status: 'success', profissional: profissional }.to_json
      else
        status 422
        { 
          error: 'Erro ao criar profissional',
          detalhes: profissional.errors.messages
        }.to_json
      end
    rescue => e
      status 500
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- ATUALIZAR PROFISSIONAL ---
  put '/:id' do
    begin
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']
      
      if params_data.empty?
        status 400
        return { error: "Dados não fornecidos" }.to_json
      end
      
      profissional = Professional.find_by(
        company_id: company_id,
        professional_id: params[:id].to_i
      )
      
      unless profissional
        status 404
        return { error: 'Profissional não encontrado' }.to_json
      end
      
      # Montar campos para atualizar
      update_fields = {}
      update_fields[:name] = params_data['name'] if params_data['name']
      update_fields[:email] = params_data['email'] if params_data['email']
      update_fields[:phone] = params_data['phone'] if params_data['phone']
      update_fields[:cpf] = params_data['cpf'] if params_data['cpf']
      update_fields[:registration_number] = params_data['registration_number'] if params_data['registration_number']
      update_fields[:specialty] = params_data['specialty'] if params_data['specialty']
      update_fields[:color] = params_data['color'] if params_data['color']
      update_fields[:status] = params_data['status'] if params_data['status']
      
      if profissional.update_attributes(update_fields)
        { status: 'success', profissional: profissional }.to_json
      else
        status 422
        { 
          error: 'Erro ao atualizar profissional',
          detalhes: profissional.errors.messages
        }.to_json
      end
    rescue => e
      status 500
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- DELETAR PROFISSIONAL ---
  delete '/:id' do
    begin
      company_id = env['current_company_id']
      
      profissional = Professional.find_by(
        company_id: company_id,
        professional_id: params[:id].to_i
      )
      
      unless profissional
        status 404
        return { error: 'Profissional não encontrado' }.to_json
      end
      
      # Verificar se tem consultas vinculadas
      if profissional.appointments.exists?
        status 409
        return { 
          error: 'Não é possível excluir',
          reason: 'Profissional possui consultas vinculadas'
        }.to_json
      end
      
      profissional.destroy
      
      { 
        status: 'success',
        mensagem: 'Profissional excluído com sucesso',
        professional_id: profissional.professional_id
      }.to_json
    rescue => e
      status 500
      { error: "Erro ao deletar", mensagem: e.message }.to_json
    end
  end
end
