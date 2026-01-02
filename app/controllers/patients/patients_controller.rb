# frozen_string_literal: true

module Patients
  class PatientsController < Sinatra::Base
    configure do
      enable :logging
      set :method_override, true
    end

    before do
      content_type :json

      # Verificar autenticação
      halt 401, { error: 'Não autenticado' }.to_json unless env['current_user_id']

      # Machine pode acessar todas empresas, outros só sua empresa
      @current_company_id = env['current_user_role'] == 'machine' ? nil : env['current_company_id']
    end

    # --- LISTAR PACIENTES ---
    get '/' do
      # LGPD: Apenas usuários da empresa podem ver pacientes
      halt 403, { error: 'Acesso negado: dados protegidos por LGPD' }.to_json unless @current_company_id

      result = Patients::PatientsService.list(@current_company_id, params)

      status 200
      result.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao listar pacientes', message: e.message }.to_json
    end

    # --- BUSCAR PACIENTE POR CPF ---
    get '/cpf/:cpf' do
      halt 403, { error: 'Acesso negado: dados protegidos por LGPD' }.to_json unless @current_company_id

      patient = Patients::PatientsService.find_by_cpf(@current_company_id, params[:cpf])

      if patient
        status 200
        { status: 'success', patient: patient_detailed_hash(patient) }.to_json
      else
        status 404
        { error: 'Paciente não encontrado com este CPF' }.to_json
      end
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar paciente', message: e.message }.to_json
    end

    # --- BUSCAR PACIENTE POR ID ---
    get '/:id' do
      patient = Patients::PatientsService.find(@current_company_id, params[:id])

      status 200
      { status: 'success', patient: patient_detailed_hash(patient) }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Paciente não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar paciente', message: e.message }.to_json
    end

    # --- CRIAR PACIENTE ---
    post '/' do
      params_data = env['parsed_json'] || {}

      if params_data['name'].to_s.strip.empty? || params_data['phone'].to_s.strip.empty?
        status 400
        return { error: 'Nome e telefone são obrigatórios' }.to_json
      end

      halt 403, { error: 'Acesso negado: dados protegidos por LGPD' }.to_json unless @current_company_id

      company_id = @current_company_id

      patient = Patients::PatientsService.create(company_id, params_data)

      status 201
      { status: 'success', message: 'Paciente criado com sucesso', patient: patient_detailed_hash(patient) }.to_json
    rescue StandardError => e
      # Service pode lançar erro de validação
      if e.is_a?(ArgumentError)
        status 400
        return { error: e.message }.to_json
      elsif e.message =~ /Não é possível deletar paciente|histórico|Erro ao criar paciente|validation/i
        status 422
        return { error: e.message }.to_json
      end

      status 500
      { error: 'Erro interno', message: e.message }.to_json
    end

    # --- ATUALIZAR PACIENTE ---
    put '/:id' do
      params_data = env['parsed_json'] || {}

      if params_data.empty?
        status 400
        return { error: 'Nenhum dado enviado para atualização' }.to_json
      end

      patient = Patients::PatientsService.update(@current_company_id, params[:id], params_data)

      status 200
      { status: 'success', message: 'Paciente atualizado com sucesso',
        patient: patient_detailed_hash(patient) }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Paciente não encontrado' }.to_json
    rescue ArgumentError => e
      status 400
      { error: e.message }.to_json
    rescue StandardError => e
      if e.message =~ /Nenhum campo válido para atualizar|validation/i
        status 422
        { error: e.message }.to_json
      else
        status 500
        { error: 'Erro ao atualizar paciente', message: e.message }.to_json
      end
    end

    # --- DELETAR PACIENTE ---
    delete '/:id' do
      Patients::PatientsService.delete(@current_company_id, params[:id])

      status 200
      { status: 'success', message: 'Paciente deletado com sucesso' }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Paciente não encontrado' }.to_json
    rescue StandardError => e
      if e.message =~ /Não é possível deletar paciente com histórico/
        status 409
        return { error: e.message }.to_json
      end

      status 500
      { error: 'Erro ao deletar paciente', message: e.message }.to_json
    end

    # --- HISTÓRICO DO PACIENTE ---
    get '/:id/history' do
      result = Patients::PatientsService.history(@current_company_id, params[:id])

      status 200
      result.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Paciente não encontrado' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar histórico', message: e.message }.to_json
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
end
