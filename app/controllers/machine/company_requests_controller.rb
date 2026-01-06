# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative '../../models/company_request'

module Machine
  class CompanyRequestsController < Sinatra::Base
    configure do
      enable :logging
      set :method_override, true
    end

    before do
      content_type :json

      if env['current_user_role'] != 'machine'
        halt 403, { error: 'Acesso negado. Esta rota é exclusiva para machines.' }.to_json
      end
    end

    # GET /api/machine/company_requests
    # Params: page, per_page, status, plan, email
    get '/' do
      page = [(params['page'] || 1).to_i, 1].max
      per_page = [[(params['per_page'] || 20).to_i, 1].max, 100].min

      q = CompanyRequest.all
      q = q.where(status: params['status']) if params['status']
      q = q.where(plan: params['plan']) if params['plan']
      q = q.where(email: params['email']) if params['email']

      total = q.count
      items = q.order_by(created_at: :desc).skip((page - 1) * per_page).limit(per_page).map do |r|
        {
          id: r.id.to_s,
          name: r.name,
          email: r.email,
          plan: r.plan,
          phone: r.phone,
          status: r.status,
          notes: r.notes,
          referrer: r.referrer,
          utm_source: r.utm_source,
          utm_campaign: r.utm_campaign,
          address: r.address,
          city: r.city,
          state: r.state,
          country: r.country,
          zip: r.zip,
          max_users: r.max_users,
          created_at: r.created_at
        }
      end

      status 200
      {
        status: 'success',
        data: items,
        meta: {
          page: page,
          per_page: per_page,
          total: total,
          total_pages: (total.to_f / per_page).ceil
        }
      }.to_json
    rescue StandardError => e
      status 500
      { error: 'Erro ao listar company_requests', mensagem: e.message }.to_json
    end
  end
end
