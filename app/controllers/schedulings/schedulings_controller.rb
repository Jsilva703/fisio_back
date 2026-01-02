# frozen_string_literal: true

module Schedulings
  class SchedulingsController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json
      Time.zone = 'America/Sao_Paulo' unless Time.zone
    end

    # --- POST: CRIAR/DEFINIR DIA ---
    post '/' do
      params_data = env['parsed_json'] || {}

      if params_data['date'].nil?
        status 400
        return({ error: 'Data é obrigatória' }.to_json)
      end

      company_id = env['current_company_id']
      agenda = Schedulings::SchedulingsService.create_or_update(
        company_id,
        params_data
      )

      status 201
      { status: 'success', message: 'Agenda salva', data: agenda }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    # --- LISTAR AGENDAS ---
    get '/' do
      company_id = env['current_company_id']
      schedulings = Schedulings::SchedulingsService.list_upcoming(company_id)
      { status: 'success', data: schedulings }.to_json
    end

    get '/:date' do
      company_id = env['current_company_id']
      agenda = Schedulings::SchedulingsService.find_by_date(company_id, params[:date])

      if agenda
        { status: 'success', data: agenda }.to_json
      else
        data = Date.parse(params[:date])
        { status: 'success', data: { date: data, slots: [], enabled: 0 } }.to_json
      end
    end

    get '/professional/:professional_id' do
      company_id = env['current_company_id']
      professional_id = params[:professional_id].to_i
      schedulings = Schedulings::SchedulingsService.list_by_professional(
        company_id,
        professional_id,
        params[:room_id]
      )
      { status: 'success', data: schedulings }.to_json
    end

    delete '/:date' do
      company_id = env['current_company_id']
      begin
        Schedulings::SchedulingsService.delete_by_date(company_id, params[:date])
        { status: 'success', message: 'Dia limpo' }.to_json
      rescue Mongoid::Errors::DocumentNotFound
        status 404
        { error: 'Dia não encontrado' }.to_json
      end
    end

    put '/:id' do
      begin
        agenda = Scheduling.where(id: params[:id], company_id: env['current_company_id']).first
        halt 404, { error: 'Agenda não encontrada' }.to_json unless agenda

        params_data = env['parsed_json'] || {}
        agenda = Schedulings::SchedulingsService.update_by_id(
          env['current_company_id'],
          params[:id],
          params_data
        )
        { status: 'success', message: 'Agenda atualizada', data: agenda }.to_json
      rescue StandardError => e
        status 500
        { error: 'Erro interno', mensagem: e.message }.to_json
      end
    end
  end
end
