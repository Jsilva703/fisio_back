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

      # Tenta encontrar para não criar duplicado (o Mongoid bloquearia com erro)
      # Se não achar, cria um NOVO do zero (.new)
      agenda = Scheduling.where(date: data).first || Scheduling.new(date: data)

      # Define os valores
      agenda.slots = params_data['slots'] || []
      agenda.enabled = params_data['enabled'].to_i

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

  # ... (Mantém os GET e DELETE iguais) ...
  get '/' do
    schedulings = Scheduling.where(:date.gte => Date.today).asc(:date)
    { status: 'success', data: schedulings }.to_json
  end

  get '/:date' do
    data = Date.parse(params[:date])
    agenda = Scheduling.where(date: data).first
    if agenda
      { status: 'success', data: agenda }.to_json
    else
      { status: 'success', data: { date: data, slots: [], enabled: 0 } }.to_json
    end
  end

  delete '/:date' do
    data = Date.parse(params[:date])
    agenda = Scheduling.where(date: data).first
    if agenda
      agenda.destroy
      { status: 'success', message: 'Dia limpo' }.to_json
    else
      status 404
      { error: 'Dia não encontrado' }.to_json
    end
  end
end