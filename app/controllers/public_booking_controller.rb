class PublicBookingController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
  end

  # --- LISTAR DIAS DISPONÍVEIS DE UMA EMPRESA (PÚBLICO) ---
  get '/:company_id/available-days' do
    begin
      company_id = params[:company_id]
      
      # Verificar se a empresa existe e está ativa
      company = Company.find(company_id)
      
      unless company.active?
        status 403
        return { error: "Empresa inativa ou suspensa" }.to_json
      end
      
      # Buscar agendas disponíveis (a partir de hoje)
      schedulings = Scheduling.where(
        company_id: company_id,
        :date.gte => Date.today
      ).order_by(date: :asc)
      
      # Filtrar apenas dias que têm slots disponíveis
      available_days = schedulings.select { |s| s.slots.any? && s.enabled == 0 }
      
      status 200
      {
        status: 'success',
        company: {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug
        },
        available_days: available_days.map do |schedule|
          {
            date: schedule.date,
            slots: schedule.slots,
            available_slots: schedule.slots.count
          }
        end
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Empresa não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar dias disponíveis", mensagem: e.message }.to_json
    end
  end

  # --- BUSCAR HORÁRIOS DISPONÍVEIS DE UM DIA ESPECÍFICO (PÚBLICO) ---
  get '/:company_id/available-slots/:date' do
    begin
      company_id = params[:company_id]
      date = Date.parse(params[:date])
      
      # Verificar se a empresa existe e está ativa
      company = Company.find(company_id)
      
      unless company.active?
        status 403
        return { error: "Empresa inativa ou suspensa" }.to_json
      end
      
      # Buscar agenda do dia específico
      schedule = Scheduling.where(company_id: company_id, date: date).first
      
      if schedule.nil? || schedule.enabled != 0
        status 404
        return { 
          error: "Nenhum horário disponível para esta data",
          date: date
        }.to_json
      end
      
      status 200
      {
        status: 'success',
        company: {
          id: company.id.to_s,
          name: company.name
        },
        date: date,
        available_slots: schedule.slots,
        total_slots: schedule.slots.count
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Empresa não encontrada" }.to_json
    rescue ArgumentError
      status 400
      { error: "Data inválida. Use formato YYYY-MM-DD" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar horários", mensagem: e.message }.to_json
    end
  end

  # --- CRIAR AGENDAMENTO PÚBLICO (PACIENTE AGENDA ONLINE) ---
  post '/:company_id/book' do
    begin
      company_id = params[:company_id]
      params_data = env['parsed_json'] || {}
      
      if params_data.empty?
        status 400
        return { error: "Dados inválidos" }.to_json
      end

      # Verificar se a empresa existe e está ativa
      company = Company.find(company_id)
      
      unless company.active?
        status 403
        return { error: "Empresa inativa ou suspensa" }.to_json
      end

      # 1. Preparar os dados
      data_hora_str = params_data['appointment_date'].to_s
      data_hora = Time.parse(data_hora_str)
      
      data_agenda = data_hora.in_time_zone.to_date 
      hora_slot = data_hora.in_time_zone.strftime("%H:%M")

      # 2. VERIFICAÇÃO DE DISPONIBILIDADE
      agenda = Scheduling.where(date: data_agenda, company_id: company_id).first

      if agenda.nil? || !agenda.slots.include?(hora_slot)
        status 409
        return { error: "Desculpe, o horário das #{hora_slot} já não está disponível." }.to_json
      end

      # 3. Criar o Agendamento
      appointment = Appointment.new(
        patient_name: params_data['patient_name'],
        patient_phone: params_data['patient_phone'],
        patiente_document: params_data['patiente_document'] || 'N/A',
        type: params_data['type'] || 'clinic',
        address: params_data['address'],
        appointment_date: data_hora,
        duration: params_data['duration'] || 60,
        price: params_data['price'].to_f,
        company_id: company_id
      )

      if appointment.save
        # 4. CONSUMIR A VAGA
        agenda.pull(slots: hora_slot)

        status 201
        return { 
          status: 'success',
          message: 'Agendamento realizado com sucesso!',
          appointment: {
            id: appointment.id.to_s,
            patient_name: appointment.patient_name,
            appointment_date: appointment.appointment_date,
            type: appointment.type,
            address: appointment.address,
            price: appointment.price
          }
        }.to_json
      else
        status 422
        return { error: "Erro ao salvar agendamento", detalhes: appointment.errors.messages }.to_json
      end

    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Empresa não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- INFORMAÇÕES DA EMPRESA POR SLUG (PÚBLICO) ---
  get '/clinic/:slug' do
    begin
      company = Company.find_by(slug: params[:slug])
      
      unless company
        status 404
        return { error: "Clínica não encontrada" }.to_json
      end
      
      status 200
      {
        status: 'success',
        clinic: {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug,
          email: company.email,
          phone: company.phone,
          address: company.address,
          plan: company.plan,
          settings: company.settings,
          status: company.status,
          is_active: company.active?
        }
      }.to_json
      
    rescue => e
      status 500
      { error: "Erro ao buscar informações", message: e.message }.to_json
    end
  end

  # --- INFORMAÇÕES DA EMPRESA POR ID (PÚBLICO) ---
  get '/:company_id/info' do
    begin
      company = Company.find(params[:company_id])
      
      status 200
      {
        status: 'success',
        company: {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug,
          email: company.email,
          phone: company.phone,
          address: company.address,
          status: company.status
        }
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Empresa não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar informações", mensagem: e.message }.to_json
    end
  end

  # --- VERIFICAR SE PACIENTE EXISTE (PÚBLICO) ---
  get '/:company_id/check-patient' do
    begin
      company = Company.find(params[:company_id])
      
      unless company.active?
        status 403
        return { error: "Clínica temporariamente indisponível" }.to_json
      end
      
      # Buscar por CPF ou telefone
      cpf = params[:cpf]
      phone = params[:phone]
      
      if cpf.blank? && phone.blank?
        status 400
        return { error: "Informe CPF ou telefone para buscar" }.to_json
      end
      
      patient = nil
      
      # Buscar por CPF primeiro
      if cpf.present?
        patient = Patient.where(company_id: company.id.to_s, cpf: cpf).first
      end
      
      # Se não encontrou por CPF, busca por telefone
      if patient.nil? && phone.present?
        patient = Patient.where(company_id: company.id.to_s, phone: phone).first
      end
      
      if patient
        status 200
        {
          status: 'success',
          patient_exists: true,
          patient: {
            id: patient.id.to_s,
            name: patient.name,
            email: patient.email,
            phone: patient.phone,
            cpf: patient.cpf,
            birth_date: patient.birth_date,
            total_appointments: patient.total_appointments,
            last_appointment: patient.last_appointment&.date
          }
        }.to_json
      else
        status 200
        {
          status: 'success',
          patient_exists: false,
          message: "Paciente não encontrado. Você pode se cadastrar."
        }.to_json
      end
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Clínica não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro ao verificar paciente", message: e.message }.to_json
    end
  end

  # --- AGENDAMENTO PÚBLICO COM AUTO-CADASTRO (por company_id) ---
  post '/:company_id/book-appointment' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Buscar empresa por ID
      company = Company.find(params[:company_id])
      
      unless company.active?
        status 403
        return { error: "Clínica temporariamente indisponível" }.to_json
      end
      
      # Validar campos obrigatórios
      if params_data['patient_name'].to_s.strip.empty? || 
         params_data['patient_phone'].to_s.strip.empty? || 
         params_data['date'].to_s.strip.empty? || 
         params_data['time'].to_s.strip.empty?
        status 400
        return { error: "Campos obrigatórios: patient_name, patient_phone, date, time" }.to_json
      end
      
      # 1. Verificar/Criar Paciente
      patient = nil
      if params_data['patient_cpf'].present?
        patient = Patient.where(company_id: company.id.to_s, cpf: params_data['patient_cpf']).first
      end
      
      # Se não encontrou por CPF, busca por telefone
      if patient.nil? && params_data['patient_phone'].present?
        patient = Patient.where(company_id: company.id.to_s, phone: params_data['patient_phone']).first
      end
      
      is_new_patient = patient.nil?
      
      # Se ainda não existe, cria
      if patient.nil?
        patient = Patient.create!(
          company_id: company.id,
          name: params_data['patient_name'],
          phone: params_data['patient_phone'],
          email: params_data['patient_email'],
          cpf: params_data['patient_cpf'],
          source: 'online_booking'
        )
      end
      
      # 2. Processar data/hora
      data_agenda = Date.parse(params_data['date'])
      hora_slot = params_data['time']
      data_hora = Time.parse("#{params_data['date']} #{params_data['time']}")
      
      # 3. Verificar disponibilidade
      agenda = Scheduling.where(date: data_agenda, company_id: company.id).first
      
      if agenda.nil? || !agenda.slots.include?(hora_slot)
        status 409
        return { error: "Horário #{hora_slot} não disponível para #{data_agenda}" }.to_json
      end
      
      # 4. Criar agendamento
      appointment = Appointment.new(
        company_id: company.id,
        patient_id: patient.id,
        patient_name: patient.name,
        patient_phone: patient.phone,
        patiente_document: patient.cpf || 'N/A',
        type: params_data['service_type'] || 'clinic',
        procedure: params_data['procedure'] || 'Consulta',
        address: params_data['address'],
        appointment_date: data_hora,
        duration: 60,
        price: 0,
        status: 'scheduled',
        payment_status: 'pending'
      )
      
      if appointment.save
        # 5. Remover slot da agenda
        agenda.slots.delete(hora_slot)
        agenda.save
        
        status 201
        {
          status: 'success',
          message: 'Consulta agendada com sucesso!',
          is_new: is_new_patient,
          appointment: {
            id: appointment.id.to_s,
            date: data_agenda.to_s,
            time: hora_slot,
            formatted_date: data_hora.strftime("%d/%m/%Y às %H:%M"),
            procedure: appointment.procedure,
            status: appointment.status
          },
          patient: {
            id: patient.id.to_s,
            name: patient.name,
            phone: patient.phone,
            cpf: patient.cpf
          }
        }.to_json
      else
        status 422
        { error: "Erro ao agendar", details: appointment.errors.messages }.to_json
      end
      
    rescue Date::Error, ArgumentError
      status 400
      { error: "Data ou hora inválida. Use formato: date='YYYY-MM-DD' e time='HH:MM'" }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Clínica não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro ao processar agendamento", message: e.message }.to_json
    end
  end

  # --- CADASTRO PÚBLICO DE PACIENTE ---
  post '/:company_id/register-patient' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Buscar empresa por ID
      company = Company.find(params[:company_id])
      
      unless company.active?
        status 403
        return { error: "Clínica temporariamente indisponível" }.to_json
      end
      
      # Validar campos obrigatórios
      if params_data['name'].to_s.strip.empty? || params_data['phone'].to_s.strip.empty?
        status 400
        return { error: "Nome e telefone são obrigatórios" }.to_json
      end
      
      # Verificar se CPF já existe (se foi informado)
      if params_data['cpf'].present?
        existing = Patient.where(company_id: company.id.to_s, cpf: params_data['cpf']).first
        if existing
          status 409
          return { 
            error: "CPF já cadastrado",
            patient_id: existing.id.to_s
          }.to_json
        end
      end
      
      # Criar paciente
      patient = Patient.new(
        company_id: company.id,
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        cpf: params_data['cpf'],
        birth_date: params_data['birth_date'],
        gender: params_data['gender'],
        address: params_data['address'] || {},
        notes: params_data['notes'],
        source: 'online_booking'
      )
      
      if patient.save
        status 201
        {
          status: 'success',
          message: 'Cadastro realizado com sucesso!',
          patient: {
            id: patient.id.to_s,
            name: patient.name,
            email: patient.email,
            phone: patient.phone
          }
        }.to_json
      else
        status 422
        { error: "Erro ao cadastrar", details: patient.errors.messages }.to_json
      end
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Clínica não encontrada" }.to_json
    rescue => e
      status 500
      { error: "Erro interno", message: e.message }.to_json
    end
  end

  # --- CADASTRO PÚBLICO DE PACIENTE ---
  post '/clinic/:slug/register-patient' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Buscar empresa por slug
      company = Company.find_by(slug: params[:slug])
      
      unless company
        status 404
        return { error: "Clínica não encontrada" }.to_json
      end
      
      unless company.active?
        status 403
        return { error: "Clínica temporariamente indisponível" }.to_json
      end
      
      # Validar campos obrigatórios
      if params_data['name'].to_s.strip.empty? || params_data['phone'].to_s.strip.empty?
        status 400
        return { error: "Nome e telefone são obrigatórios" }.to_json
      end
      
      # Verificar se CPF já existe (se foi informado)
      if params_data['cpf'].present?
        existing = Patient.where(company_id: company.id.to_s, cpf: params_data['cpf']).first
        if existing
          status 409
          return { 
            error: "CPF já cadastrado",
            patient_id: existing.id.to_s
          }.to_json
        end
      end
      
      # Criar paciente
      patient = Patient.new(
        company_id: company.id,
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        cpf: params_data['cpf'],
        birth_date: params_data['birth_date'],
        gender: params_data['gender'],
        address: params_data['address'] || {},
        notes: params_data['notes'],
        source: 'online_booking'
      )
      
      if patient.save
        status 201
        {
          status: 'success',
          message: 'Cadastro realizado com sucesso!',
          patient: {
            id: patient.id.to_s,
            name: patient.name,
            email: patient.email,
            phone: patient.phone
          }
        }.to_json
      else
        status 422
        { error: "Erro ao cadastrar", details: patient.errors.messages }.to_json
      end
      
    rescue => e
      status 500
      { error: "Erro interno", message: e.message }.to_json
    end
  end

  # --- AGENDAMENTO PÚBLICO COM AUTO-CADASTRO ---
  post '/clinic/:slug/book-appointment' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Buscar empresa por slug
      company = Company.find_by(slug: params[:slug])
      
      unless company
        status 404
        return { error: "Clínica não encontrada" }.to_json
      end
      
      unless company.active?
        status 403
        return { error: "Clínica temporariamente indisponível" }.to_json
      end
      
      # Validar campos obrigatórios
      required_fields = ['patient_name', 'patient_phone', 'appointment_date']
      missing_fields = required_fields.select { |f| params_data[f].to_s.strip.empty? }
      
      if missing_fields.any?
        status 400
        return { error: "Campos obrigatórios faltando: #{missing_fields.join(', ')}" }.to_json
      end
      
      # 1. Verificar/Criar Paciente
      patient = nil
      if params_data['patient_cpf'].present?
        patient = Patient.where(company_id: company.id.to_s, cpf: params_data['patient_cpf']).first
      end
      
      # Se não encontrou por CPF, busca por telefone
      if patient.nil? && params_data['patient_phone'].present?
        patient = Patient.where(company_id: company.id.to_s, phone: params_data['patient_phone']).first
      end
      
      # Se ainda não existe, cria
      if patient.nil?
        patient = Patient.create!(
          company_id: company.id,
          name: params_data['patient_name'],
          phone: params_data['patient_phone'],
          email: params_data['patient_email'],
          cpf: params_data['patient_cpf'],
          source: 'online_booking'
        )
      end
      
      # 2. Processar data/hora
      data_hora = Time.parse(params_data['appointment_date'])
      data_agenda = data_hora.in_time_zone.to_date
      hora_slot = data_hora.in_time_zone.strftime("%H:%M")
      
      # 3. Verificar disponibilidade
      agenda = Scheduling.where(date: data_agenda, company_id: company.id).first
      
      if agenda.nil? || !agenda.slots.include?(hora_slot)
        status 409
        return { error: "Horário #{hora_slot} não disponível para #{data_agenda}" }.to_json
      end
      
      # 4. Criar agendamento
      appointment = Appointment.new(
        company_id: company.id,
        patient_id: patient.id,
        patient_name: patient.name,
        patient_phone: patient.phone,
        patiente_document: patient.cpf || 'N/A',
        type: params_data['type'] || 'clinic',
        procedure: params_data['procedure'] || 'Consulta',
        address: params_data['address'],
        appointment_date: data_hora,
        duration: params_data['duration'] || 60,
        price: params_data['price']&.to_f || 0,
        status: 'scheduled',
        payment_status: 'pending'
      )
      
      if appointment.save
        # 5. Consumir vaga
        agenda.pull(slots: hora_slot)
        
        status 201
        {
          status: 'success',
          message: 'Agendamento realizado com sucesso!',
          appointment: {
            id: appointment.id.to_s,
            patient_name: appointment.patient_name,
            patient_phone: appointment.patient_phone,
            date: appointment.date,
            time: appointment.time,
            procedure: appointment.procedure,
            type: appointment.type,
            address: appointment.address,
            price: appointment.price
          },
          patient: {
            id: patient.id.to_s,
            name: patient.name,
            is_new: patient.created_at > 1.minute.ago
          }
        }.to_json
      else
        status 422
        { error: "Erro ao criar agendamento", details: appointment.errors.messages }.to_json
      end
      
    rescue => e
      status 500
      { error: "Erro interno", message: e.message, backtrace: e.backtrace.first(3) }.to_json
    end
  end

  # --- LISTAR HORÁRIOS DISPONÍVEIS POR SLUG ---
  get '/clinic/:slug/available-days' do
    begin
      company = Company.find_by(slug: params[:slug])
      
      unless company
        status 404
        return { error: "Clínica não encontrada" }.to_json
      end
      
      unless company.active?
        status 403
        return { error: "Clínica temporariamente indisponível" }.to_json
      end
      
      # Buscar agendas disponíveis (próximos 30 dias)
      start_date = Date.today
      end_date = start_date + 30.days
      
      schedulings = Scheduling.where(
        company_id: company.id,
        :date.gte => start_date,
        :date.lte => end_date,
        enabled: 0
      ).order_by(date: :asc)
      
      # Filtrar apenas dias com slots disponíveis
      available_days = schedulings.select { |s| s.slots.any? }.map do |schedule|
        {
          date: schedule.date,
          weekday: Date.parse(schedule.date.to_s).strftime('%A'),
          slots: schedule.slots,
          available_slots: schedule.slots.count
        }
      end
      
      status 200
      {
        status: 'success',
        clinic: {
          name: company.name,
          slug: company.slug
        },
        period: {
          start: start_date,
          end: end_date
        },
        total_days: available_days.count,
        available_days: available_days
      }.to_json
      
    rescue => e
      status 500
      { error: "Erro ao buscar horários", message: e.message }.to_json
    end
  end

  # --- BUSCAR SLOTS DE UM DIA ESPECÍFICO POR SLUG ---
  get '/clinic/:slug/slots/:date' do
    begin
      company = Company.find_by(slug: params[:slug])
      
      unless company
        status 404
        return { error: "Clínica não encontrada" }.to_json
      end
      
      date = Date.parse(params[:date])
      
      # Buscar agenda do dia
      schedule = Scheduling.where(
        company_id: company.id,
        date: date,
        enabled: 0
      ).first
      
      if schedule.nil? || schedule.slots.empty?
        status 404
        return {
          error: "Nenhum horário disponível para esta data",
          date: date
        }.to_json
      end
      
      status 200
      {
        status: 'success',
        clinic: {
          name: company.name,
          slug: company.slug
        },
        date: date,
        weekday: date.strftime('%A'),
        available_slots: schedule.slots,
        total_slots: schedule.slots.count
      }.to_json
      
    rescue ArgumentError
      status 400
      { error: "Data inválida. Use formato YYYY-MM-DD" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar horários", message: e.message }.to_json
    end
  end
end
