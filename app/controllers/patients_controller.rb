class PatientsController < Sinatra::Base
  configure do
    enable :logging
    set :method_override, true
  end

  before do
    content_type :json
    
    # Verificar autenticação
    unless env['current_user_id']
      halt 401, { error: 'Não autenticado' }.to_json
    end
    
    # Machine pode acessar todas empresas, outros só sua empresa
    @current_company_id = env['current_user_role'] == 'machine' ? nil : env['current_company_id']
  end

  # --- LISTAR PACIENTES ---
  get '/' do
    begin
      query = {}
      
      # LGPD: Apenas usuários da empresa podem ver pacientes
      # Machine NÃO tem acesso a dados de pacientes
      halt 403, { error: 'Acesso negado: dados protegidos por LGPD' }.to_json unless @current_company_id
      
      query[:company_id] = @current_company_id
      
      # Filtros
      query[:status] = params[:status] if params[:status]
      
      # Busca por nome, email, phone ou CPF
      if params[:search]
        search_term = /#{Regexp.escape(params[:search])}/i
        query['$or'] = [
          { name: search_term },
          { email: search_term },
          { phone: search_term },
          { cpf: search_term }
        ]
      end
      
      patients = Patient.where(query).order_by(created_at: :desc)
      
      # Paginação
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 20).to_i
      total = patients.count
      patients = patients.skip((page - 1) * per_page).limit(per_page)
      
      patients_data = patients.map do |patient|
        {
          id: patient.id.to_s,
          name: patient.name,
          email: patient.email,
          phone: patient.phone,
          cpf: patient.cpf,
          birth_date: patient.birth_date,
          age: patient.age,
          gender: patient.gender,
          status: patient.status,
          company_id: patient.company_id.to_s,
          total_appointments: patient.total_appointments,
          last_appointment: patient.last_appointment&.date,
          created_at: patient.created_at
        }
      end
      
      status 200
      {
        status: 'success',
        total: total,
        page: page,
        per_page: per_page,
        total_pages: (total.to_f / per_page).ceil,
        patients: patients_data
      }.to_json
      
    rescue => e
      status 500
      { error: "Erro ao listar pacientes", message: e.message }.to_json
    end
  end

  # --- BUSCAR PACIENTE POR ID ---
  get '/:id' do
    begin
      patient = find_patient(params[:id])
      
      status 200
      {
        status: 'success',
        patient: patient_detailed_hash(patient)
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Paciente não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar paciente", message: e.message }.to_json
    end
  end

  # --- CRIAR PACIENTE ---
  post '/' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Validar campos obrigatórios
      if params_data['name'].to_s.strip.empty? || params_data['phone'].to_s.strip.empty?
        status 400
        return { error: "Nome e telefone são obrigatórios" }.to_json
      end
      
      # LGPD: Machine não pode criar pacientes
      # Apenas usuários da empresa podem criar
      halt 403, { error: 'Acesso negado: dados protegidos por LGPD' }.to_json unless @current_company_id
      
      company_id = @current_company_id
      
      if company_id.nil?
        status 400
        return { error: "company_id é obrigatório" }.to_json
      end
      
      # Criar paciente
      patient = Patient.new(
        company_id: company_id,
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        cpf: params_data['cpf'],
        rg: params_data['rg'],
        birth_date: params_data['birth_date'],
        gender: params_data['gender'],
        address: params_data['address'] || {},
        blood_type: params_data['blood_type'],
        allergies: params_data['allergies'] || [],
        medications: params_data['medications'] || [],
        health_insurance: params_data['health_insurance'] || {},
        emergency_contact: params_data['emergency_contact'] || {},
        notes: params_data['notes'],
        source: params_data['source'] || 'manual'
      )
      
      if patient.save
        status 201
        {
          status: 'success',
          message: 'Paciente criado com sucesso',
          patient: patient_detailed_hash(patient)
        }.to_json
      else
        status 422
        { error: "Erro ao criar paciente", details: patient.errors.messages }.to_json
      end
      
    rescue => e
      status 500
      { error: "Erro interno", message: e.message }.to_json
    end
  end

  # --- ATUALIZAR PACIENTE ---
  put '/:id' do
    begin
      params_data = env['parsed_json'] || {}
      
      if params_data.empty?
        status 400
        return { error: "Nenhum dado enviado para atualização" }.to_json
      end
      
      patient = find_patient(params[:id])
      
      # Campos permitidos
      allowed_fields = [
        'name', 'email', 'phone', 'cpf', 'rg', 'birth_date', 'gender',
        'address', 'blood_type', 'allergies', 'medications',
        'health_insurance', 'emergency_contact', 'status', 'notes'
      ]
      
      update_data = params_data.select { |k, v| allowed_fields.include?(k) }
      
      if update_data.empty?
        status 400
        return { error: "Nenhum campo válido para atualizar" }.to_json
      end
      
      if patient.update(update_data)
        status 200
        {
          status: 'success',
          message: 'Paciente atualizado com sucesso',
          patient: patient_detailed_hash(patient)
        }.to_json
      else
        status 422
        { error: "Erro ao atualizar paciente", details: patient.errors.messages }.to_json
      end
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Paciente não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao atualizar paciente", message: e.message }.to_json
    end
  end

  # --- DELETAR PACIENTE ---
  delete '/:id' do
    begin
      patient = find_patient(params[:id])
      
      # Verificar se tem prontuários ou consultas
      if patient.medical_records.exists? || patient.appointments.exists?
        status 409
        return {
          error: "Não é possível deletar paciente com histórico",
          medical_records_count: patient.medical_records.count,
          appointments_count: patient.appointments.count,
          suggestion: "Altere o status para 'inactive' ao invés de deletar"
        }.to_json
      end
      
      patient.delete
      
      status 200
      { status: 'success', message: 'Paciente deletado com sucesso' }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Paciente não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao deletar paciente", message: e.message }.to_json
    end
  end

  # --- HISTÓRICO DO PACIENTE ---
  get '/:id/history' do
    begin
      patient = find_patient(params[:id])
      
      # Buscar consultas
      appointments = patient.appointments.order_by(date: :desc).limit(50)
      
      # Buscar prontuários
      medical_records = patient.medical_records.order_by(date: :desc).limit(50)
      
      status 200
      {
        status: 'success',
        patient: {
          id: patient.id.to_s,
          name: patient.name,
          age: patient.age
        },
        appointments: appointments.map { |a| appointment_summary(a) },
        medical_records: medical_records.map { |mr| medical_record_summary(mr) }
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Paciente não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar histórico", message: e.message }.to_json
    end
  end

  private

  def find_patient(id)
    query = { _id: id }
    
    # LGPD: Apenas usuários da empresa podem acessar pacientes
    halt 403, { error: 'Acesso negado: dados protegidos por LGPD' }.to_json unless @current_company_id
    
    query[:company_id] = @current_company_id
    
    Patient.find_by(query)
  end

  def patient_detailed_hash(patient)
    {
      id: patient.id.to_s,
      company_id: patient.company_id.to_s,
      name: patient.name,
      email: patient.email,
      phone: patient.phone,
      cpf: patient.cpf,
      rg: patient.rg,
      birth_date: patient.birth_date,
      age: patient.age,
      gender: patient.gender,
      address: patient.address,
      blood_type: patient.blood_type,
      allergies: patient.allergies,
      medications: patient.medications,
      health_insurance: patient.health_insurance,
      emergency_contact: patient.emergency_contact,
      status: patient.status,
      notes: patient.notes,
      source: patient.source,
      total_appointments: patient.total_appointments,
      last_appointment: patient.last_appointment&.date,
      created_at: patient.created_at,
      updated_at: patient.updated_at
    }
  end

  def appointment_summary(appointment)
    {
      id: appointment.id.to_s,
      date: appointment.date,
      time: appointment.time,
      status: appointment.status,
      procedure: appointment.procedure
    }
  end

  def medical_record_summary(record)
    {
      id: record.id.to_s,
      date: record.date,
      time: record.time,
      record_type: record.record_type,
      chief_complaint: record.chief_complaint,
      professional: record.professional_name
    }
  end
end
