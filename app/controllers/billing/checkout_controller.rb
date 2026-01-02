# frozen_string_literal: true

require 'sinatra/base'
require 'json'
# Mercado Pago integration removed
require_relative '../../models/subscription'
require_relative '../../models/payment'
require_relative '../../models/invoice'
require_relative '../../models/company'

module Billing
  class CheckoutController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json
    end

    # GET /api/billing/checkout/public_key
    # Deprecated: backend no longer exposes payment public keys.
    get '/public_key' do
      status 410
      { error: 'payments_externalized', message: 'Public key is not served by backend. Configure payment provider panel and front-end directly.' }.to_json
    end

    # Deprecated: Payments handled directly in Mercado Pago panel.
    # Keep the route but return information so the front knows to use Mercado Pago panel.
    post '/:company_id/create_preference' do
      status 410
      { error: 'payments_externalized', message: 'Payments must be created in the Mercado Pago panel. Backend no longer creates preferences.' }.to_json
    end

    # Deprecated: Payments handled directly in Mercado Pago panel.
    post '/:company_id/create_payment' do
      status 410
      { error: 'payments_externalized', message: 'Payments must be created in the Mercado Pago panel. Backend no longer processes payments.' }.to_json
    end

    # POST /api/billing/checkout/save_card
    # Body: { card_token, payer: { email, first_name, last_name } }
    post '/save_card' do
      begin
        data = env['parsed_json'] || {}
        card_token = data['card_token'] || data['token']
        payer = data['payer'] || {}

        if card_token.nil? || payer['email'].nil?
          status 400
          return({ error: 'missing_card_token_or_payer' }.to_json)
        end

        status 410
        { error: 'payments_externalized', message: 'Saving cards is handled in the payment provider. Backend no longer creates customers.' }.to_json
      rescue StandardError => e
        status 500
        { error: 'internal_error', message: e.message }.to_json
      end
    end

    # POST /api/billing/checkout/webhook
    # Mercado Pago will POST notifications here; we'll process and update Payment/Subscription
    post '/webhook' do
      begin
        request.body.rewind
        body = request.body.read
        data = JSON.parse(body) rescue {}

        topic = params['type'] || data['type'] || env['HTTP_X_MELI_SIGNATURE']
        # Mercado Pago usually sends: { "action": "payment.created", "data": { "id": 12345 } }
        resource_id = data.dig('data', 'id') || params['id'] || params['data.id']

        if resource_id.nil?
          status 400
          return({ error: 'missing_resource_id' }.to_json)
        end

        status 410
        { error: 'payments_externalized', message: 'Webhook handling for Mercado Pago removed. Payments are managed via the payment provider panel.' }.to_json
      rescue StandardError => e
        status 500
        { error: 'internal_error', message: e.message }.to_json
      end
    end
  end
end
