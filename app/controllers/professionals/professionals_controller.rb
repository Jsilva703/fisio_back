# frozen_string_literal: true

module Professionals
  class ProfessionalsController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json

      if request.content_type&.include?('application/json') && request.body.read.length.positive?
        request.body.rewind
        env['parsed_json'] = JSON.parse(request.body.read)
      end
    end

    # --- LISTAR PROFISSIONAIS ---
    get '/' do
      company_id = env['current_company_id']

      professionals = Professionals::ProfessionalsService.list(company_id, params)

      { status: 'success', profissionais: professionals }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar profissionais', mensagem: e.message }.to_json
    end

    get '/:id/appointments' do
      company_id = env['current_company_id']
      professional_id = params[:id].to_i

      start_date = params[:start_date] ? Time.parse(params[:start_date]) : Time.now.beginning_of_month
      end_date = params[:end_date] ? Time.parse(params[:end_date]) : Time.now.end_of_month

      appointments = Appointment.where(
        company_id: company_id,
        professional_id: professional_id,
        :appointment_date.ne => nil, # <-- Adiciona este filtro!
        :appointment_date.gte => start_date,
        :appointment_date.lte => end_date
      ).asc(:appointment_date)

      { status: 'success', atendimentos: appointments, count: appointments.count }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar atendimentos', mensagem: e.message }.to_json
    end

    get '/appointments/count' do
      company_id = env['current_company_id']

      start_date = params[:start_date] ? Time.parse(params[:start_date]) : Time.now.beginning_of_month
      end_date = params[:end_date] ? Time.parse(params[:end_date]) : Time.now.end_of_month

      appointments = Appointment.where(
        company_id: company_id,
        :appointment_date.ne => nil, # <-- Adiciona este filtro!
        :appointment_date.gte => start_date,
        :appointment_date.lte => end_date
      ).asc(:appointment_date)

      { status: 'success', atendimentos: appointments, count: appointments.count }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar atendimentos', mensagem: e.message }.to_json
    end

    # --- BUSCAR PROFISSIONAL POR ID ---
    get '/:id' do
      company_id = env['current_company_id']

      profissional = Professionals::ProfessionalsService.find_by_company(company_id, params[:id])

      unless profissional
        status 404
        return { error: 'Profissional não encontrado' }.to_json
      end

      { status: 'success', profissional: profissional }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar profissional', mensagem: e.message }.to_json
    end

    # --- CRIAR PROFISSIONAL ---
    post '/' do
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']

      if params_data.empty?
        status 400
        return { error: 'Dados inválidos' }.to_json
      end

      profissional = Professionals::ProfessionalsService.create(company_id, params_data)

      status 201
      { status: 'success', profissional: profissional }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    # --- ATUALIZAR PROFISSIONAL ---
    put '/:id' do
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']

      if params_data.empty?
        status 400
        return { error: 'Dados não fornecidos' }.to_json
      end

      profissional = Professionals::ProfessionalsService.find_by_company(company_id, params[:id])

      unless profissional
        status 404
        return { error: 'Profissional não encontrado' }.to_json
      end

      # Montar campos para atualizar
      update_fields = {}
      update_fields[:name] = params_data['name'] if params_data['name']
      update_fields[:email] = params_data['email'] if params_data['email']
      update_fields[:phone] = params_data['phone'] if params_data['phone']
      update_fields[:cpf] = params_data['cpf'] if params_data['cpf']
      update_fields[:registration_number] = params_data['registration_number'] if params_data['registration_number']
      update_fields[:specialty] = params_data['specialty'] if params_data['specialty']
      update_fields[:color] = params_data['color'] if params_data['color']
      update_fields[:status] = params_data['status'] if params_data['status']

      profissional = Professionals::ProfessionalsService.update(company_id, params[:id], params_data)

      { status: 'success', profissional: profissional }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    # --- DELETAR PROFISSIONAL ---
    delete '/:id' do
      company_id = env['current_company_id']

      Professionals::ProfessionalsService.delete(company_id, params[:id])

      { status: 'success', mensagem: 'Profissional excluído com sucesso', professional_id: params[:id].to_i }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao deletar', mensagem: e.message }.to_json
    end
  end
end
