class AppointmentsController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
    
    # Parse JSON body
    if request.content_type&.include?('application/json') && request.body.read.length > 0
      request.body.rewind
      env['parsed_json'] = JSON.parse(request.body.read)
    end
  end

  # --- CRIAR AGENDAMENTO ---
  post '/' do
    begin
      params_data = env['parsed_json'] || {}
      
      if params_data.empty?
        status 400
        return { error: "Dados inválidos" }.to_json
      end

      # 1. Preparar dados
      data_hora = Time.parse(params_data['appointment_date'].to_s)
      data_agenda = data_hora.in_time_zone.to_date 
      hora_slot = data_hora.in_time_zone.strftime("%H:%M")
      company_id = env['current_company_id']
      
      # 2. Buscar agenda
      agenda = Scheduling.where(date: data_agenda, company_id: company_id).first
      
      if agenda.nil?
        status 404
        return { error: "Agenda não encontrada para esta data" }.to_json
      end
      
      # 3. TENTAR RESERVAR O SLOT (operação atômica)
      unless agenda.reserve_slot(hora_slot)
        status 409
        return { error: "Horário #{hora_slot} não está disponível" }.to_json
      end

      # 4. Validar paciente
      patient_id = params_data['patient_id']
      
      unless patient_id.present?
        agenda.release_slot(hora_slot)  # DEVOLVER slot se der erro
        status 400
        return { error: "Campo patient_id é obrigatório" }.to_json
      end
      
      patient = Patient.where(id: patient_id, company_id: company_id).first
      
      unless patient
        agenda.release_slot(hora_slot)  # DEVOLVER slot se paciente não existir
        status 404
        return { error: "Paciente não encontrado ou não pertence a esta empresa" }.to_json
      end

      # 5. Criar consulta
      appointment = Appointment.new(
        patient_id: patient_id,
        patient_name: patient.name,
        patient_phone: patient.phone,
        patiente_document: patient.cpf,
        type: params_data['type'] || 'clinic',
        address: params_data['address'],
        appointment_date: data_hora,
        price: params_data['price'].to_f,
        company_id: company_id
      )

      if appointment.save
        status 201
        return { status: 'success', agendamento: appointment }.to_json
      else
        # Se falhar ao salvar, DEVOLVER o slot
        agenda.release_slot(hora_slot)
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
      
      if params_data.empty?
        status 400
        return { error: "Dados não fornecidos" }.to_json
      end
      
      # Busca pelo ID E company_id (segurança)
      appointment = Appointment.where(id: params[:id], company_id: company_id).first
      
      if appointment.nil?
        status 404
        return { error: "Agendamento não encontrado" }.to_json
      end
      
      # Se está alterando data/hora, validar disponibilidade e ajustar slots
      if params_data['appointment_date'].present?
        # Novo horário
        data_hora_nova = Time.parse(params_data['appointment_date'].to_s)
        data_agenda_nova = data_hora_nova.in_time_zone.to_date
        hora_slot_nova = data_hora_nova.in_time_zone.strftime("%H:%M")
        
        # Horário antigo
        data_hora_antiga = appointment.appointment_date
        data_agenda_antiga = data_hora_antiga.in_time_zone.to_date
        hora_slot_antiga = data_hora_antiga.in_time_zone.strftime("%H:%M")
        
        # Buscar agenda nova
        agenda_nova = Scheduling.where(date: data_agenda_nova, company_id: company_id).first
        
        if agenda_nova.nil?
          status 404
          return { error: "Agenda não encontrada para #{data_agenda_nova}" }.to_json
        end
        
        # TENTAR RESERVAR novo slot
        unless agenda_nova.reserve_slot(hora_slot_nova)
          status 409
          return { error: "Horário #{hora_slot_nova} não está disponível" }.to_json
        end
        
        # DEVOLVER slot antigo
        agenda_antiga = Scheduling.where(date: data_agenda_antiga, company_id: company_id).first
        if agenda_antiga
          agenda_antiga.release_slot(hora_slot_antiga)
        end
      end
      
      # Atualizar consulta
      if appointment.update(params_data)
        status 200
        { status: 'success', agendamento: appointment }.to_json
      else
        # Se falhar ao atualizar e mudou horário, reverter
        if params_data['appointment_date'].present?
          agenda_nova.release_slot(hora_slot_nova)
          agenda_antiga.reserve_slot(hora_slot_antiga) if agenda_antiga
        end
        
        status 422
        { error: "Erro ao atualizar", detalhes: appointment.errors.messages }.to_json
      end
      
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
      
      # Pegar dados antes de deletar
      data_hora = appointment.appointment_date
      data_agenda = data_hora.in_time_zone.to_date
      hora_slot = data_hora.in_time_zone.strftime("%H:%M")
      
      # Deletar consulta
      if appointment.destroy
        # DEVOLVER slot para agenda
        agenda = Scheduling.where(date: data_agenda, company_id: company_id).first
        if agenda
          agenda.release_slot(hora_slot)
        end
        
        status 200
        { status: 'success', mensagem: "Agendamento cancelado e horário liberado" }.to_json
      else
        status 422
        { error: "Erro ao cancelar" }.to_json
      end
      
    rescue => e
      status 500
      { error: "Erro ao deletar", mensagem: e.message }.to_json
    end
  end
end
