class SchedulingsController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
    # GARANTIA FINAL: Define o fuso aqui para o Mongoid não explodir no .save
    Time.zone = 'America/Sao_Paulo' unless Time.zone
  end

  # --- POST: CRIAR/DEFINIR DIA ---
  post '/' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Validação
      if params_data['date'].nil?
        status 400
        return { error: "Data é obrigatória" }.to_json
      end

      data = Date.parse(params_data['date'].to_s)
      company_id = env['current_company_id']

      # Tenta encontrar para não criar duplicado DA EMPRESA
      # Se não achar, cria um NOVO do zero (.new)
      agenda = Scheduling.where(date: data, company_id: company_id).first || Scheduling.new(date: data, company_id: company_id)

      # Define os valores
      agenda.slots = params_data['slots'] || []
      agenda.enabled = params_data['enabled'].to_i
      agenda.professional_id = params_data['professional_id'].to_i
      agenda.room_id = params_data['room_id'] || nil


      # Tenta Gravar (Aqui é que dava o erro do 'local')
      if agenda.save
        status 201
        { status: 'success', message: 'Agenda salva', data: agenda }.to_json
      else
        status 422
        { error: "Erro ao salvar", detalhes: agenda.errors.messages }.to_json
      end

    rescue => e
      status 500
      # O erro 'local' vai aparecer aqui se o Time.zone falhar
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- LISTAR AGENDAS ---
  get '/' do
    company_id = env['current_company_id']
    schedulings = Scheduling.where(company_id: company_id, :date.gte => Date.today).asc(:date)
    { status: 'success', data: schedulings }.to_json
  end

  get '/:date' do
    data = Date.parse(params[:date])
    company_id = env['current_company_id']
    agenda = Scheduling.where(date: data, company_id: company_id).first
    if agenda
      { status: 'success', data: agenda }.to_json
    else
      { status: 'success', data: { date: data, slots: [], enabled: 0 } }.to_json
    end
  end

  # --- LISTAR AGENDAS ---
  get '/professional/:professional_id' do
  company_id = env['current_company_id']
  professional_id = params[:professional_id].to_i

  schedulings = Scheduling.where(
    company_id: company_id,
    professional_id: professional_id,
    :date.gte => Date.today
  )

  # Filtro opcional por room_id (se quiser)
  if params[:room_id]
    schedulings = schedulings.where(room_id: params[:room_id].to_i)
  end

  schedulings = schedulings.asc(:date)
  { status: 'success', data: schedulings }.to_json
end

  delete '/:date' do
    data = Date.parse(params[:date])
    company_id = env['current_company_id']
    agenda = Scheduling.where(date: data, company_id: company_id).first
    if agenda
      agenda.destroy
      { status: 'success', message: 'Dia limpo' }.to_json
    else
      status 404
      { error: 'Dia não encontrado' }.to_json
    end
  end

  put '/:id' do
  begin
    agenda = Scheduling.where(id: params[:id], company_id: env['current_company_id']).first
    halt 404, { error: "Agenda não encontrada" }.to_json unless agenda

    update_data = env['parsed_json'] || JSON.parse(request.body.read)
    agenda.slots = update_data['slots'] if update_data['slots']
    agenda.date = Date.parse(update_data['date']) if update_data['date']
    agenda.professional_id = update_data['professional_id'].to_i if update_data['professional_id']
    agenda.room_id = update_data['room_id'] if update_data['room_id']
    agenda.enabled = update_data['enabled'].to_i if update_data['enabled']

    if agenda.save
      { status: 'success', message: 'Agenda atualizada', data: agenda }.to_json
    else
      status 422
      { error: "Erro ao atualizar", detalhes: agenda.errors.messages }.to_json
    end
  rescue => e
    status 500
    { error: "Erro interno", mensagem: e.message }.to_json
  end
end
end