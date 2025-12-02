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

  # --- INFORMAÇÕES DA EMPRESA (PÚBLICO) ---
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
end
