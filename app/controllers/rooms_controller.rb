class RoomsController < Sinatra::Base
  configure do
    enable :logging
  end

  before do
    content_type :json

    if request.content_type&.include?('application/json') && request.body.read.length > 0
      request.body.rewind
      env['parsed_json'] = JSON.parse(request.body.read)
    end
  end

  # --- CRIAR SALA ---
  post '/' do
    begin 
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']

      if params_data.empty?
        status 400
        return { error: "Dados inválidos" }.to_json
      end

      room = Room.new(
        name: params_data['name'],
        description: params_data['description'],
        capacity: params_data['capacity'] || 1,
        color: params_data['color'] || '#10B981',
        company_id: company_id
      )

      if room.save
        status 201
        { status: 'success', sala: room }.to_json
      else
        status 422
        { error: "Não foi possível criar a sala", detalhes: room.errors.messages }.to_json
      end
    rescue => e
      status 500
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end

  # --- LISTAR SALAS ---
  get '/' do
    begin 
      company_id = env['current_company_id']

      rooms = Room.where(company_id: company_id)

      if params[:status]
        rooms = rooms.where(status: params[:status])
      end
      
      if params[:search]
        rooms = rooms.where(
          :name => /#{Regexp.escape(params[:search])}/i
        )
      end

      rooms = rooms.order_by(room_id: :asc)

      { status: 'success', salas: rooms }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar salas", mensagem: e.message }.to_json
    end
  end

  # --- BUSCAR SALA POR ID ---
  get '/:id' do
    begin 
      company_id = env['current_company_id']

      room = Room.find_by(
        company_id: company_id,
        room_id: params[:id].to_i
      )

      unless room
        status 404
        return { error: 'Sala não encontrada' }.to_json
      end
      
      { status: 'success', sala: room }.to_json
    rescue => e
      status 500
      { error: "Erro ao buscar sala", mensagem: e.message }.to_json
    end
  end

  # --- ATUALIZAR SALA ---
  put '/:id' do
    begin 
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']

      if params_data.empty?
        status 400
        return { error: "Dados não fornecidos" }.to_json
      end

      room = Room.find_by(
        company_id: company_id,
        room_id: params[:id].to_i
      )

      unless room 
        status 404
        return { error: 'Sala não encontrada' }.to_json
      end

      # Montar campos para atualizar
      update_fields = {}
      update_fields[:name] = params_data['name'] if params_data['name']
      update_fields[:description] = params_data['description'] if params_data['description']
      update_fields[:capacity] = params_data['capacity'] if params_data['capacity']
      update_fields[:color] = params_data['color'] if params_data['color']
      update_fields[:status] = params_data['status'] if params_data['status']

      if room.update_attributes(update_fields)
        { status: 'success', sala: room }.to_json
      else
        status 422
        { 
          error: 'Erro ao atualizar sala',
          detalhes: room.errors.messages
        }.to_json
      end
    rescue => e
      status 500
      { error: "Erro interno", mensagem: e.message }.to_json
    end
  end
end