class AppointmentsController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json
  end

  # --- CRIAR AGENDAMENTO ---
  post '/' do
    begin
      params_data = env['parsed_json'] || {}
      
      if params_data.empty?
        status 400
        return { error: "Dados inválidos ou vazio" }.to_json
      end

      appointment = Appointment.new(
        patient_name:     params_data['patient_name'],
        patient_phone:    params_data['patient_phone'],
        type:             params_data['type'] || 'clinic',
        address:          params_data['address'],
        appointment_date: Time.parse(params_data['appointment_date'].to_s),
        price:            params_data['price'].to_f
      )

      if appointment.save
        status 201
        return { status: 'success', agendamento: appointment }.to_json
      else
        status 422
        return { error: "Erro ao salvar", detalhes: appointment.errors.messages }.to_json
      end
    rescue => e
      status 500
      return { error: "Erro interno", mensagem: e.message, erro: e.class.to_s }.to_json
    end
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
      params_data = env['parsed_json'] || {}
      
      appointment = Appointment.find(params[:id])
      appointment.update(params_data) if !params_data.empty?
      
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
