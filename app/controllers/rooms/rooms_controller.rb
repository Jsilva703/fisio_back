# frozen_string_literal: true

module Rooms
  class RoomsController < Sinatra::Base
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

    # --- CRIAR SALA ---
    post '/' do
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']

      if params_data.empty?
        status 400
        return { error: 'Dados inválidos' }.to_json
      end

      room = Rooms::RoomsService.create(company_id, params_data)

      status 201
      { status: 'success', sala: room }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    # --- LISTAR SALAS ---
    get '/' do
      company_id = env['current_company_id']
      rooms = Rooms::RoomsService.list(company_id, params)

      { status: 'success', salas: rooms }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar salas', mensagem: e.message }.to_json
    end

    # --- BUSCAR SALA POR ID ---
    get '/:id' do
      company_id = env['current_company_id']
      room = Rooms::RoomsService.find_by_company(company_id, params[:id])

      unless room
        status 404
        return { error: 'Sala não encontrada' }.to_json
      end

      { status: 'success', sala: room }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar sala', mensagem: e.message }.to_json
    end

    # --- ATUALIZAR SALA ---
    put '/:id' do
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']

      if params_data.empty?
        status 400
        return { error: 'Dados não fornecidos' }.to_json
      end

      room = Rooms::RoomsService.update(company_id, params[:id], params_data)

      { status: 'success', sala: room }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    delete '/:id' do
      company_id = env['current_company_id']

      Rooms::RoomsService.delete(company_id, params[:id])

      { status: 'success', message: 'Sala deletada com sucesso' }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end
  end
end
