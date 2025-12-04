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

      # 3. Buscar ou criar paciente (se tiver CPF)
      patient_id = nil
      cpf = params_data['patiente_document']
      
      if cpf.present? && !cpf.strip.empty?
        # Busca paciente existente pelo CPF na empresa
        existing_patient = Patient.where(
          company_id: company_id,
          cpf: cpf
        ).first
        
        if existing_patient
          patient_id = existing_patient.id
        else
          # Cria novo paciente se não existe
          new_patient = Patient.new(
            company_id: company_id,
            name: params_data['patient_name'],
            phone: params_data['patient_phone'],
            cpf: cpf,
            source: 'manual'
          )
          
          if new_patient.save
            patient_id = new_patient.id
          end
        end
      end

      # 4. Criar o Agendamento
      appointment = Appointment.new(
        patient_id:       patient_id,
        patient_name:     params_data['patient_name'],
        patient_phone:    params_data['patient_phone'],
        patiente_document: cpf,
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

  # --- ATUALIZAR AGENDAMENTO ---
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
      
      # Atualiza só o que veio (status, pagamento, etc.)
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
