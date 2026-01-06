# frozen_string_literal: true

module Admin
  class UsersController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json
      require 'active_support/time'
      Time.zone ||= ActiveSupport::TimeZone['America/Sao_Paulo']
    end

    helpers do
      def require_admin!(env)
        role = env['current_user_role']
        halt 403, { error: 'Acesso negado' }.to_json unless role == 'admin'
      end

      def current_company_id(env)
        env['current_company_id']
      end
    end

    # List users for the current company
    get '/' do
      require_admin!(env)
      company_id = current_company_id(env)
      users = User.where(company_id: company_id).only(:id, :name, :email, :role, :status, :phone, :created_at).to_a
      { status: 'success', data: users.map { |u| u.as_json } }.to_json
    end

    # Create a new user under the current company
    post '/' do
      require_admin!(env)
      params_data = env['parsed_json'] || {}
      company_id = current_company_id(env)

      user = User.new(
        name: params_data['name'],
        email: params_data['email'],
        phone: params_data['phone'],
        role: params_data['role'] || 'atendente',
        company_id: company_id
      )
      user.password = params_data['password'] || SecureRandom.hex(8)

      if user.save
        status 201
        { status: 'success', data: user.as_json }.to_json
      else
        status 422
        { error: 'validation_failed', messages: user.errors.full_messages }.to_json
      end
    end

    # Update user
    put '/:id' do
      require_admin!(env)
      params_data = env['parsed_json'] || {}
      company_id = current_company_id(env)

      user = User.where(id: params[:id], company_id: company_id).first
      halt 404, { error: 'not_found' }.to_json unless user

      user.name = params_data['name'] if params_data['name']
      user.email = params_data['email'] if params_data['email']
      user.phone = params_data['phone'] if params_data['phone']
      user.role = params_data['role'] if params_data['role']
      user.status = params_data['status'] if params_data['status']
      user.password = params_data['password'] if params_data['password']

      if user.save
        { status: 'success', data: user.as_json }.to_json
      else
        status 422
        { error: 'validation_failed', messages: user.errors.full_messages }.to_json
      end
    end

    # Delete (soft delete) user
    delete '/:id' do
      require_admin!(env)
      company_id = current_company_id(env)
      user = User.where(id: params[:id], company_id: company_id).first
      halt 404, { error: 'not_found' }.to_json unless user

      user.status = 'inactive'
      user.save
      { status: 'success' }.to_json
    end
  end
end
