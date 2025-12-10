class MedicalRecordsController < Sinatra::Base
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
    
    @current_company_id = env['current_user_role'] == 'machine' ? nil : env['current_company_id']
    @current_user_id = env['current_user_id']
  end

  # --- LISTAR PRONTUÁRIOS DE UM PACIENTE ---
  get '/patient/:patient_id' do
    begin
      patient = find_patient(params[:patient_id])
      
      medical_records = patient.medical_records.order_by(date: :desc, created_at: :desc)
      
      records_data = medical_records.map do |record|
        {
          id: record.id.to_s,
          date: record.date,
          time: record.time,
          record_type: record.record_type,
          chief_complaint: record.chief_complaint,
          diagnosis: record.diagnosis,
          pain_scale: record.pain_scale,
          status: record.status,
          professional: record.professional_name,
          created_by_id: record.created_by_id&.to_s,
          created_at: record.created_at,
          is_recent: record.is_recent?
        }
      end
      
      status 200
      {
        status: 'success',
        patient: {
          id: patient.id.to_s,
          name: patient.name
        },
        total: records_data.count,
        medical_records: records_data
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Paciente não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao listar prontuários", message: e.message }.to_json
    end
  end

  # --- BUSCAR PRONTUÁRIO POR ID ---
  get '/:id' do
    begin
      record = find_medical_record(params[:id])
      
      status 200
      {
        status: 'success',
        medical_record: record_detailed_hash(record)
      }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Prontuário não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar prontuário", message: e.message }.to_json
    end
  end

  # --- CRIAR PRONTUÁRIO ---
  post '/' do
    begin
      params_data = env['parsed_json'] || {}
      
      # Validar patient_id
      if params_data['patient_id'].to_s.strip.empty?
        status 400
        return { error: "patient_id é obrigatório" }.to_json
      end
      
      # Buscar paciente
      patient = find_patient(params_data['patient_id'])
      
      # Criar prontuário
      record = MedicalRecord.new(
        patient_id: patient.id,
        company_id: patient.company_id,
        created_by_id: @current_user_id,
        record_type: params_data['record_type'] || 'evolution',
        date: params_data['date'],
        time: params_data['time'],
        chief_complaint: params_data['chief_complaint'],
        history: params_data['history'],
        physical_exam: params_data['physical_exam'],
        diagnosis: params_data['diagnosis'],
        treatment_plan: params_data['treatment_plan'],
        evolution: params_data['evolution'],
        procedures: params_data['procedures'] || [],
        vital_signs: params_data['vital_signs'] || {},
        tests: params_data['tests'] || [],
        pain_scale: params_data['pain_scale'],
        goals: params_data['goals'] || [],
        next_steps: params_data['next_steps'],
        attachments: params_data['attachments'] || [],
        notes: params_data['notes'],
        appointment_id: params_data['appointment_id']
      )
      
      if record.save
        status 201
        {
          status: 'success',
          message: 'Prontuário criado com sucesso',
          medical_record: record_detailed_hash(record)
        }.to_json
      else
        status 422
        { error: "Erro ao criar prontuário", details: record.errors.messages }.to_json
      end
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Paciente não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro interno", message: e.message }.to_json
    end
  end

  # --- ATUALIZAR PRONTUÁRIO ---
  put '/:id' do
    begin
      params_data = env['parsed_json'] || {}
      
      if params_data.empty?
        status 400
        return { error: "Nenhum dado enviado para atualização" }.to_json
      end
      
      record = find_medical_record(params[:id])
      
      # Campos permitidos
      allowed_fields = [
        'record_type', 'date', 'time', 'chief_complaint', 'history',
        'physical_exam', 'diagnosis', 'treatment_plan', 'evolution',
        'procedures', 'vital_signs', 'tests', 'pain_scale', 'goals',
        'next_steps', 'attachments', 'status', 'notes'
      ]
      
      update_data = params_data.select { |k, v| allowed_fields.include?(k) }
      
      if update_data.empty?
        status 400
        return { error: "Nenhum campo válido para atualizar" }.to_json
      end
      
      if record.update(update_data)
        status 200
        {
          status: 'success',
          message: 'Prontuário atualizado com sucesso',
          medical_record: record_detailed_hash(record)
        }.to_json
      else
        status 422
        { error: "Erro ao atualizar prontuário", details: record.errors.messages }.to_json
      end
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Prontuário não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao atualizar prontuário", message: e.message }.to_json
    end
  end

  # --- DELETAR PRONTUÁRIO ---
  delete '/:id' do
    begin
      record = find_medical_record(params[:id])
      
      # Apenas machine ou criador pode deletar
      unless env['current_user_role'] == 'machine' || record.created_by_id.to_s == @current_user_id
        status 403
        return { error: "Apenas o criador do prontuário ou machine pode deletá-lo" }.to_json
      end
      
      record.delete
      
      status 200
      { status: 'success', message: 'Prontuário deletado com sucesso' }.to_json
      
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Prontuário não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao deletar prontuário", message: e.message }.to_json
    end
  end

    get '/' do
    begin
      company_id = env['current_company_id']
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 20).to_i

      records = MedicalRecord.where(company_id: company_id)
                            .skip((page - 1) * per_page)
                            .limit(per_page)
                            .desc(:created_at)

      { status: 'success', prontuarios: records, page: page, per_page: per_page, total: records.count }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar prontuários", mensagem: e.message }.to_json
    end
  end

  # --- BUSCAR PRONTUÁRIOS POR PERÍODO ---
  get '/company/period' do
    begin
      # Validar datas
      start_date = params[:start_date]
      end_date = params[:end_date]
      
      if start_date.nil? || end_date.nil?
        status 400
        return { error: "start_date e end_date são obrigatórios (formato: YYYY-MM-DD)" }.to_json
      end
      
      query = { date: { '$gte' => start_date, '$lte' => end_date } }
      
      # Machine pode filtrar por empresa
      if env['current_user_role'] == 'machine'
        query[:company_id] = params[:company_id] if params[:company_id]
      else
        query[:company_id] = @current_company_id
      end
      
      records = MedicalRecord.where(query).order_by(date: :desc)
      
      records_data = records.map do |record|
        {
          id: record.id.to_s,
          patient_name: record.patient.name,
          patient_id: record.patient_id.to_s,
          date: record.date,
          time: record.time,
          record_type: record.record_type,
          chief_complaint: record.chief_complaint,
          professional: record.professional_name
        }
      end
      
      status 200
      {
        status: 'success',
        period: { start_date: start_date, end_date: end_date },
        total: records_data.count,
        medical_records: records_data
      }.to_json
      
    rescue => e
      status 500
      { error: "Erro ao buscar prontuários", message: e.message }.to_json
    end
  end

  private

  def find_patient(id)
    query = { _id: id }
    
    unless env['current_user_role'] == 'machine'
      query[:company_id] = @current_company_id
    end
    
    Patient.find_by(query)
  end

  def find_medical_record(id)
    query = { _id: id }
    
    unless env['current_user_role'] == 'machine'
      query[:company_id] = @current_company_id
    end
    
    MedicalRecord.find_by(query)
  end

  def record_detailed_hash(record)
    {
      id: record.id.to_s,
      patient: {
        id: record.patient_id.to_s,
        name: record.patient.name,
        age: record.patient.age
      },
      company_id: record.company_id.to_s,
      created_by: {
        id: record.created_by_id&.to_s,
        name: record.professional_name
      },
      appointment_id: record.appointment_id&.to_s,
      record_type: record.record_type,
      date: record.date,
      time: record.time,
      chief_complaint: record.chief_complaint,
      history: record.history,
      physical_exam: record.physical_exam,
      diagnosis: record.diagnosis,
      treatment_plan: record.treatment_plan,
      evolution: record.evolution,
      procedures: record.procedures,
      vital_signs: record.vital_signs,
      tests: record.tests,
      pain_scale: record.pain_scale,
      goals: record.goals,
      next_steps: record.next_steps,
      attachments: record.attachments,
      status: record.status,
      notes: record.notes,
      is_recent: record.is_recent?,
      created_at: record.created_at,
      updated_at: record.updated_at
    }
  end
end
