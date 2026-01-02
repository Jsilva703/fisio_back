# frozen_string_literal: true

module Appointments
  class AppointmentsController < Sinatra::Base
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

    # --- CRIAR AGENDAMENTO ---
    post '/' do
      params_data = env['parsed_json'] || {}
      if params_data.empty?
        status 400
        return { error: 'Dados inválidos' }.to_json
      end
      result = Appointments::CreateService.call(params_data, env)
      status result[:status]
      result[:body].to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end
    # --- LISTAR AGENDAMENTOS ---
    get '/' do
      result = Appointments::ListService.call(env, params)
      status result[:status]
      result[:body].to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar agendamentos', mensagem: e.message }.to_json
    end

    # --- BUSCAR AGENDAMENTO POR ID ---
    get '/:id' do
      result = Appointments::ShowService.call(params[:id], env)
      status result[:status]
      result[:body].to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao buscar agendamento', mensagem: e.message }.to_json
    end
    # --- ATUALIZAR AGENDAMENTO (REAGENDAR) ---
    patch '/:id' do
      params_data = env['parsed_json'] || {}
      result = Appointments::UpdateService.call(params[:id], params_data, env)
      status result[:status]
      result[:body].to_json
    rescue StandardError => e
      status 500
      { error: 'Erro interno', mensagem: e.message }.to_json
    end

    # --- DELETAR AGENDAMENTO ---
    delete '/:id' do
      result = Appointments::DeleteService.call(params[:id], env)
      status result[:status]
      result[:body].to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao deletar', mensagem: e.message }.to_json
    end
  end
end
