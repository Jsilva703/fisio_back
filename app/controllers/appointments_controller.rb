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

      # Pegar company_id do token
      company_id = env['current_company_id']
      
      # 2. VERIFICAÇÃO DE DISPONIBILIDADE (Regra de Ouro) 🛡️
      # Busca a configuração daquele dia DA EMPRESA
      agenda = Scheduling.where(date: data_agenda, company_id: company_id).first

      # Se não tem agenda, ou o horário não está na lista 'slots'
      if agenda.nil? || !agenda.slots.include?(hora_slot)
        status 409 # Conflict
        return { error: "Desculpe, o horário das #{hora_slot} já não está disponível." }.to_json
      end

      # 3. VALIDAR que o paciente existe (obrigatório)
      patient_id = params_data['patient_id']
      
      unless patient_id.present?
        status 400
        return { error: "Campo patient_id é obrigatório" }.to_json
      end
      
      # Verifica se o paciente existe e pertence à empresa
      patient = Patient.where(
        id: patient_id,
        company_id: company_id
      ).first
      
      unless patient
        status 404
        return { error: "Paciente não encontrado ou não pertence a esta empresa" }.to_json
      end

      # 4. Criar o Agendamento
      appointment = Appointment.new(
        patient_id:       patient_id,
        patient_name:     patient.name,
        patient_phone:    patient.phone,
        patiente_document: patient.cpf,
        type:             params_data['type'] || 'clinic',
        address:          params_data['address'],
        appointment_date: data_hora,
        price:            params_data['price'].to_f,
        company_id:       company_id
      )

      if appointment.save
        # 5. CONSUMIR A VAGA (O que pediste!) ✂️
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
      # Filtrar apenas agendamentos DA EMPRESA do usuário
      company_id = env['current_company_id']
      agendamentos = Appointment.where(company_id: company_id).desc(:appointment_date)
      { status: 'success', agendamentos: agendamentos }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar agendamentos", mensagem: e.message }.to_json
    end
  end

  # --- BUSCAR AGENDAMENTO POR ID ---
  get '/:id' do
    begin
      company_id = env['current_company_id']
      appointment = Appointment.where(id: params[:id], company_id: company_id).first
      
      if appointment.nil?
        status 404
        return { error: "Agendamento não encontrado" }.to_json
      end
      
      { status: 'success', agendamento: appointment }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar agendamento", mensagem: e.message }.to_json
    end
  end

  # --- ATUALIZAR AGENDAMENTO (REAGENDAR) ---
  patch '/:id' do
    begin
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']
      
      # Busca pelo ID E company_id (segurança)
      appointment = Appointment.where(id: params[:id], company_id: company_id).first
      
      if appointment.nil?
        status 404
        return { error: "Agendamento não encontrado" }.to_json
      end
      
      # Se está alterando data/hora, validar disponibilidade e ajustar slots
      if params_data['appointment_date']
        # Novo horário
        data_hora_nova = Time.parse(params_data['appointment_date'].to_s)
        data_agenda_nova = data_hora_nova.in_time_zone.to_date
        hora_slot_nova = data_hora_nova.in_time_zone.strftime("%H:%M")
        
        # Horário antigo
        data_hora_antiga = appointment.appointment_date
        data_agenda_antiga = data_hora_antiga.in_time_zone.to_date
        hora_slot_antiga = data_hora_antiga.in_time_zone.strftime("%H:%M")
        
        # Verificar se novo horário está disponível
        agenda_nova = Scheduling.where(date: data_agenda_nova, company_id: company_id).first
        
        if agenda_nova.nil? || !agenda_nova.slots.include?(hora_slot_nova)
          status 409
          return { error: "Horário #{hora_slot_nova} não está disponível para #{data_agenda_nova}" }.to_json
        end
        
        # DEVOLVER o horário antigo para a agenda
        agenda_antiga = Scheduling.where(date: data_agenda_antiga, company_id: company_id).first
        if agenda_antiga && !agenda_antiga.slots.include?(hora_slot_antiga)
          agenda_antiga.push(slots: hora_slot_antiga)
        end
        
        # CONSUMIR o novo horário
        agenda_nova.pull(slots: hora_slot_nova)
      end
      
      # Atualiza os campos enviados
      appointment.update(params_data) unless params_data.empty?
      
      { status: 'success', agendamento: appointment }.to_json
      
    rescue => e
      status 500
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- DELETAR AGENDAMENTO ---
  delete '/:id' do
    begin
      company_id = env['current_company_id']
      appointment = Appointment.where(id: params[:id], company_id: company_id).first
      
      if appointment.nil?
        status 404
        return { error: "Agendamento não encontrado" }.to_json
      end
      
      appointment.delete
      
      { status: 'success', mensagem: "Agendamento deletado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao deletar", mensagem: e.message }.to_json
    end
  end
end
