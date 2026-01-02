# frozen_string_literal: true

module MedicalRecords
  class MedicalRecordsController < Sinatra::Base
    configure do
      enable :logging
      set :method_override, true
    end

    before do
      content_type :json

      # Verificar autenticação
      halt 401, { error: 'Não autenticado' }.to_json unless env['current_user_id']

      @current_company_id = env['current_user_role'] == 'machine' ? nil : env['current_company_id']
      @current_user_id = env['current_user_id']
    end

    # --- LISTAR PRONTUÁRIOS DE UM PACIENTE ---
    get '/patient/:patient_id' do
      records = MedicalRecords::MedicalRecordsService.list_by_patient(@current_company_id, params[:patient_id])

      status 200
      {
        status: 'success',
        patient: { id: params[:patient_id], name: Patient.find(params[:patient_id]).name },
        total: records.count,
        medical_records: records
      }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Paciente não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao listar prontuários', message: e.message }.to_json
    end

    # --- BUSCAR PRONTUÁRIO POR ID ---
    get '/:id' do
      record = MedicalRecords::MedicalRecordsService.find(@current_company_id, params[:id])

      status 200
      { status: 'success', medical_record: record_detailed_hash(record) }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Prontuário não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar prontuário', message: e.message }.to_json
    end

    # --- CRIAR PRONTUÁRIO ---
    post '/' do
      params_data = env['parsed_json'] || {}

      # Validar patient_id
      if params_data['patient_id'].to_s.strip.empty?
        status 400
        return { error: 'patient_id é obrigatório' }.to_json
      end

      record = MedicalRecords::MedicalRecordsService.create(@current_user_id, params_data)

      status 201
      { status: 'success', message: 'Prontuário criado com sucesso',
        medical_record: record_detailed_hash(record) }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Paciente não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', message: e.message }.to_json
    end

    # --- ATUALIZAR PRONTUÁRIO ---
    put '/:id' do
      params_data = env['parsed_json'] || {}

      if params_data.empty?
        status 400
        return { error: 'Nenhum dado enviado para atualização' }.to_json
      end

      record = MedicalRecords::MedicalRecordsService.update(@current_company_id, params[:id], params_data)

      status 200
      { status: 'success', message: 'Prontuário atualizado com sucesso',
        medical_record: record_detailed_hash(record) }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Prontuário não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao atualizar prontuário', message: e.message }.to_json
    end

    # --- DELETAR PRONTUÁRIO ---
    delete '/:id' do
      MedicalRecords::MedicalRecordsService.delete(env['current_user_role'], @current_user_id, @current_company_id,
                                                   params[:id])

      status 200
      { status: 'success', message: 'Prontuário deletado com sucesso' }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Prontuário não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao deletar prontuário', message: e.message }.to_json
    end

    get '/' do
      company_id = env['current_company_id']
      result = MedicalRecords::MedicalRecordsService.list(company_id, params)

      result.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar prontuários', mensagem: e.message }.to_json
    end

    # --- BUSCAR PRONTUÁRIOS POR PERÍODO ---
    get '/company/period' do
      # Validar datas
      start_date = params[:start_date]
      end_date = params[:end_date]

      if start_date.nil? || end_date.nil?
        status 400
        return { error: 'start_date e end_date são obrigatórios (formato: YYYY-MM-DD)' }.to_json
      end

      machine_role = env['current_user_role'] == 'machine'
      machine_company_id = params[:company_id]

      records_data = MedicalRecords::MedicalRecordsService.period(@current_company_id, start_date, end_date,
                                                                  machine_role: machine_role, machine_company_id: machine_company_id)

      status 200
      {
        status: 'success',
        period: { start_date: start_date, end_date: end_date },
        total: records_data.count,
        medical_records: records_data
      }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar prontuários', message: e.message }.to_json
    end

    private

    def find_patient(id)
      query = { _id: id }

      query[:company_id] = @current_company_id unless env['current_user_role'] == 'machine'

      Patient.find_by(query)
    end

    def find_medical_record(id)
      query = { _id: id }

      query[:company_id] = @current_company_id unless env['current_user_role'] == 'machine'

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
end
