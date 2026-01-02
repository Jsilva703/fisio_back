# frozen_string_literal: true

module Expenses
  class ExpensesController < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      content_type :json
      Time.zone = 'America/Sao_Paulo' unless Time.zone
    end

    post '/' do
      params_data = env['parsed_json'] || {}
      company_id = env['current_company_id']
      created_by = env['current_user_id'] || env['current_user'] || nil

      expense = Expenses::ExpensesService.create(company_id, params_data, created_by)

      status 201
      { status: 'success', data: expense.as_json }.to_json
    rescue StandardError => e
      status 400
      { error: 'invalid', message: e.message }.to_json
    end

    get '/' do
      company_id = env['current_company_id']
      list = Expenses::ExpensesService.list_by_company(company_id)
      serialized = list.map(&:as_json)
      total = serialized.reduce(0.0) { |s, e| s + (e[:amount] || 0.0) }
      { status: 'success', data: serialized, meta: { count: serialized.size, total_amount: total } }.to_json
    end
  end
end
