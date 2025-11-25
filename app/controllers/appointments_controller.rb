class AppointmentsController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
  end

  # --- CRIAR AGENDAMENTO ---
  post '/' do
    # Ler corretamente o corpo da requisição
    begin
      request.body.rewind
      body = request.body.read
      
      if body.empty?
        status 400
        return { error: "Corpo da requisição vazio" }.to_json
      end
      
      request_payload = JSON.parse(body)
    rescue JSON::ParserError => e
      status 400
      return { error: "JSON inválido", detalhes: e.message }.to_json
    end

    appointment = Appointment.new(
      patient_name:     request_payload['patient_name'],
      patient_phone:    request_payload['patient_phone'],
      type:             request_payload['type'] || 'clinic',
      address:          request_payload['address'],
      appointment_date: request_payload['appointment_date'],
      price:            request_payload['price']
    )

    if appointment.save
      status 201
      return { status: 'success', agendamento: appointment }.to_json
    else
      status 422
      return { error: "Erro ao salvar", detalhes: appointment.errors.to_h }.to_json
    end
  rescue => e
    status 500
    return { error: "Erro interno", mensagem: e.message }.to_json
  end

  # --- LISTAR AGENDAMENTOS ---
  get '/' do
    begin
      agendamentos = Appointment.all.desc(:appointment_date)
      { status: 'success', agendamentos: agendamentos }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar agendamentos", mensagem: e.message }.to_json
    end
  end

  # --- BUSCAR AGENDAMENTO POR ID ---
  get '/:id' do
    begin
      appointment = Appointment.find(params[:id])
      { status: 'success', agendamento: appointment }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Agendamento não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar agendamento", mensagem: e.message }.to_json
    end
  end

  # --- ATUALIZAR AGENDAMENTO ---
  patch '/:id' do
    begin
      request.body.rewind
      body = request.body.read
      request_payload = JSON.parse(body) unless body.empty?
      
      appointment = Appointment.find(params[:id])
      appointment.update(request_payload) if request_payload
      
      { status: 'success', agendamento: appointment }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Agendamento não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao atualizar", mensagem: e.message }.to_json
    end
  end

  # --- DELETAR AGENDAMENTO ---
  delete '/:id' do
    begin
      appointment = Appointment.find(params[:id])
      appointment.delete
      
      { status: 'success', mensagem: "Agendamento deletado" }.to_json
    rescue Mongoid::Errors::DocumentNotFound
      status 404
      { error: "Agendamento não encontrado" }.to_json
    rescue => e
      status 500
      { error: "Erro ao deletar", mensagem: e.message }.to_json
    end
  end
end