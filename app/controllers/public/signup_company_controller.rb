# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'jwt'
require_relative '../../models/company'
require_relative '../../models/user'

module Public
  class SignupCompanyController < Sinatra::Base
    configure do
      enable :logging
    end

    configure do
      require 'active_support/time'
      Time.zone ||= ActiveSupport::TimeZone['America/Sao_Paulo']
    end

    before do
      content_type :json
    end

    # POST /
    # Body: { company: { name, email, slug, cnpj, phone }, admin: { name, email, password, phone } }
    post '/' do
      begin
        data = env['parsed_json'] || {}
        company_data = data['company'] || {}
        admin_data = data['admin'] || {}

        if company_data.empty? || admin_data.empty?
          status 400
          return({ error: 'company_and_admin_required' }.to_json)
        end

        # Create company using CompaniesService (keeps logic centralized)
        require_relative '../../services/companies/companies_service'
        company_params = {
          'name' => company_data['name'],
          'email' => company_data['email'],
          'phone' => company_data['phone'],
          'cnpj' => company_data['cnpj'],
          'address' => company_data['address'],
          'plan' => company_data['plan'] || 'basic',
          'status' => company_data['status'] || 'pending',
          'max_users' => company_data['max_users']
        }

        company = Companies::CompaniesService.create(company_params)

        # Create or attach admin user
        existing_user = User.where(email: admin_data['email']).first
        if existing_user
          if existing_user.company_id.nil?
            existing_user.company_id = company.id
            existing_user.role = 'admin'
            existing_user.name = admin_data['name'] if admin_data['name']
            existing_user.phone = admin_data['phone'] if admin_data['phone']
            existing_user.password = admin_data['password'] if admin_data['password'] && existing_user.password_digest.nil?
            unless existing_user.save
              company.destroy
              status 422
              return({ error: 'user_creation_failed', messages: existing_user.errors.full_messages }.to_json)
            end
            user = existing_user
          else
            # Email already taken by a user attached to another company
            company.destroy
            status 422
            return({ error: 'user_creation_failed', messages: ['Email has already been taken'] }.to_json)
          end
        else
          user = User.new(
            name: admin_data['name'],
            email: admin_data['email'],
            phone: admin_data['phone'],
            role: 'admin',
            company_id: company.id
          )
          user.password = admin_data['password'] || SecureRandom.hex(8)

          unless user.save
            # rollback company if user creation fails
            company.destroy
            status 422
            return({ error: 'user_creation_failed', messages: user.errors.full_messages }.to_json)
          end
        end

        # Generate JWT token
        jwt_secret = ENV['JWT_SECRET'] || 'sua_chave_secreta_aqui_troque_em_producao'
        payload = {
          user_id: user.id.to_s,
          email: user.email,
          role: user.role,
          company_id: company.id.to_s,
          exp: Time.now.to_i + (24 * 3600)
        }
        token = JWT.encode(payload, jwt_secret, 'HS256')

        resp = {
          status: 'success',
          company_id: company.id.to_s,
          user_id: user.id.to_s,
          token: token,
          company: company
        }

        # Publish new company event for machine view via Redis (non-blocking for response)
        begin
          require 'redis'
          Thread.new do
            begin
              redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379')
              payload = { id: company.id.to_s, name: company.name, plan: company.plan, trial_ends_at: company.trial_ends_at&.to_s }
              redis.publish('companies:new', payload.to_json)
            rescue StandardError => e
              logger.error("Failed to publish new company event: #{e.message}") if respond_to?(:logger)
            end
          end
        rescue StandardError => e
          logger.error("Failed to spawn redis publisher thread: #{e.message}") if respond_to?(:logger)
        end

        status 201
        resp.to_json
      rescue StandardError => e
        status 500
        { error: 'internal_error', message: e.message }.to_json
      end
    end
  end
end
