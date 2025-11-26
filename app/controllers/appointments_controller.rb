class AppointmentsController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
  end

  # --- CRIAR AGENDAMENTO ---
 post '/' do
    begin
      params_data = env['parsed_json'] || {}
      
      if params_data.empty?
        status 400
        return { error: "Dados inválidos" }.to_json
      end

      # 1. Preparar os dados
      data_hora_str = params_data['appointment_date'].to_s
      data_hora = Time.parse(data_hora_str) # Ex: 2025-11-26 08:00:00 -0300
      
      # Extrair a DATA (para achar a agenda) e a HORA (string "08:00")
      # Usamos in_time_zone para garantir que não pegamos a data errada por causa de UTC
      data_agenda = data_hora.in_time_zone.to_date 
      hora_slot   = data_hora.in_time_zone.strftime("%H:%M")

      # 2. VERIFICAÇÃO DE DISPONIBILIDADE (Regra de Ouro) 🛡️
      # Busca a configuração daquele dia
      agenda = Scheduling.where(date: data_agenda).first

      # Se não tem agenda, ou o horário não está na lista 'slots'
      if agenda.nil? || !agenda.slots.include?(hora_slot)
        status 409 # Conflict
        return { error: "Desculpe, o horário das #{hora_slot} já não está disponível." }.to_json
      end

      # 3. Criar o Agendamento
      appointment = Appointment.new(
        patient_name:     params_data['patient_name'],
        patient_phone:    params_data['patient_phone'],
        type:             params_data['type'] || 'clinic',
        address:          params_data['address'],
        appointment_date: data_hora,
        price:            params_data['price'].to_f
      )

      if appointment.save
        # 4. CONSUMIR A VAGA (O que pediste!) ✂️
        # Removemos este horário específico da lista de slots disponíveis
        agenda.pull(slots: hora_slot)

        status 201
        return { status: 'success', agendamento: appointment }.to_json
      else
        status 422
        return { error: "Erro ao salvar", detalhes: appointment.errors.messages }.to_json
      end

    rescue => e
      status 500
      return { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- LISTAR AGENDAMENTOS ---
  get '/' do
    begin
      agendamentos = Appointment.all.desc(:appointment_date)
      { status: 'success', agendamentos: agendamentos }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar agendamentos", mensagem: e.message }.to_json
    end
  end

  # --- BUSCAR AGENDAMENTO POR ID ---
  get '/:id' do
    begin
      appointment = Appointment.find(params[:id])
      { status: 'success', agendamento: appointment }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Agendamento não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar agendamento", mensagem: e.message }.to_json
    end
  end

  # --- ATUALIZAR AGENDAMENTO ---
  patch '/:patient_name' do
    begin
      params_data = env['parsed_json'] || {}
      
      appointment = Appointment.find(params[:patient_name])
      appointment.update(params_data) if !params_data.empty?
      
      { status: 'success', agendamento: appointment }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Agendamento não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao atualizar", mensagem: e.message }.to_json
    end
  end

  # --- DELETAR AGENDAMENTO ---
  delete '/:id' do
    begin
      appointment = Appointment.find(params[:id])
      appointment.delete
      
      { status: 'success', mensagem: "Agendamento deletado" }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Agendamento não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao deletar", mensagem: e.message }.to_json
    end
  end
end
