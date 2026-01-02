# frozen_string_literal: true

module PublicBooking
  class PublicBookingController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json
    end

    # --- LISTAR DIAS DISPONÍVEIS DE UMA EMPRESA (PÚBLICO) ---
    get '/:company_id/available-days' do
      company_id = params[:company_id]

      # Verificar se a empresa existe e está ativa
      company = Company.find(company_id)

      unless company.active?
        status 403
        return { error: 'Empresa inativa ou suspensa' }.to_json
      end

      # Buscar agendas disponíveis (a partir de hoje)
      available_days = PublicBooking::PublicBookingService.available_days(company_id)

      status 200
      {
        status: 'success',
        company: {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug
        },
        available_days: available_days
      }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Empresa não encontrada' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar dias disponíveis', mensagem: e.message }.to_json
    end

    # --- BUSCAR HORÁRIOS DISPONÍVEIS DE UM DIA ESPECÍFICO (PÚBLICO) ---
    get '/:company_id/available-slots/:date' do
      company_id = params[:company_id]
      date = Date.parse(params[:date])

      # Verificar se a empresa existe e está ativa
      company = Company.find(company_id)

      unless company.active?
        status 403
        return { error: 'Empresa inativa ou suspensa' }.to_json
      end

      # Buscar agenda do dia específico
      result = PublicBooking::PublicBookingService.available_slots(company_id, params[:date])

      if result.nil?
        status 404
        return { error: 'Nenhum horário disponível para esta data', date: date }.to_json
      end

      status 200
      {
        status: 'success',
        company: { id: company.id.to_s, name: company.name },
        date: result[:date],
        available_slots: result[:available_slots],
        total_slots: result[:total_slots]
      }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Empresa não encontrada' }.to_json
    rescue ArgumentError
      status 400
      { error: 'Data inválida. Use formato YYYY-MM-DD' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar horários', mensagem: e.message }.to_json
    end

    # --- CRIAR AGENDAMENTO PÚBLICO (PACIENTE AGENDA ONLINE) ---
    post '/:company_id/book' do
      company_id = params[:company_id]
      params_data = env['parsed_json'] || {}

      if params_data.empty?
        status 400
        return { error: 'Dados inválidos' }.to_json
      end

      # Verificar se a empresa existe e está ativa
      company = Company.find(company_id)

      unless company.active?
        status 403
        return { error: 'Empresa inativa ou suspensa' }.to_json
      end

      # 1. Preparar os dados
      appointment = PublicBooking::PublicBookingService.book(company_id, params_data)

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
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: 'Empresa não encontrada' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    # ... (demais rotas mantidas conforme original) ...
  end
end
