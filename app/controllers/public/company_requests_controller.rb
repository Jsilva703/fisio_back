# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative '../../models/company_request'

module Public
  class CompanyRequestsController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json
    end

    # POST /api/public/company_requests
    # Body: { company: { name, email, slug, cnpj, phone, address, plan, max_users } }
    post '/' do
      begin
        data = env['parsed_json'] || {}
        # Accept both shapes: { company: { ... } } or flat { name: ..., email: ... }
        company_data = data['company'] || data

        if company_data.empty? || company_data['name'].to_s.strip == '' || company_data['email'].to_s.strip == '' || company_data['plan'].to_s.strip == ''
          status 400
          return({ error: 'company_name_email_plan_required' }.to_json)
        end

        # normalize and accept cpf/cnpj/document
        raw_doc = company_data['document'] || company_data['cnpj'] || company_data['cpf']
        normalized = raw_doc.to_s.gsub(/\D/, '') if raw_doc
        doc_type = nil
        if normalized && normalized.length == 11
          doc_type = 'cpf'
        elsif normalized && normalized.length == 14
          doc_type = 'cnpj'
        end

        req = CompanyRequest.new(
          name: company_data['name'],
          slug: company_data['slug'],
          email: company_data['email'],
          phone: company_data['phone'],
          cnpj: (doc_type == 'cnpj' ? normalized : company_data['cnpj']),
          document: normalized,
          document_type: doc_type,
          address: company_data['address'],
          city: company_data['city'],
          state: company_data['state'],
          country: company_data['country'],
          zip: company_data['zip'],
          notes: company_data['notes'],
          referrer: company_data['referrer'],
          utm_source: company_data['utm_source'],
          utm_campaign: company_data['utm_campaign'],
          plan: company_data['plan'],
          status: 'pending',
          max_users: company_data['max_users'] || 5,
          settings: company_data['settings'] || {}
        )

        unless req.save
          status 422
          return({ error: 'company_request_creation_failed', messages: req.errors.full_messages }.to_json)
        end

        # publish to redis for machine panel
        begin
          require 'redis'
          redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379')
          payload = {
            id: req.id.to_s,
            name: req.name,
            email: req.email,
            plan: req.plan,
            phone: req.phone,
            status: req.status,
            document: req.document,
            document_type: req.document_type,
            notes: req.notes,
            referrer: req.referrer,
            utm_source: req.utm_source,
            utm_campaign: req.utm_campaign,
            address: req.address,
            city: req.city,
            state: req.state,
            country: req.country,
            zip: req.zip,
            max_users: req.max_users,
            created_at: req.created_at.iso8601
          }
          redis.publish('companies:requested', payload.to_json)
        rescue StandardError => e
          logger.error("Failed to publish company request: #{e.message}") if respond_to?(:logger)
        end

        status 201
        { status: 'success', request_id: req.id.to_s, request: req }.to_json
      rescue StandardError => e
        status 500
        { error: 'internal_error', message: e.message }.to_json
      end
    end
  end
end
