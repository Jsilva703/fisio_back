# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'active_support/all'

module Billing
  class BillingController < Sinatra::Base
    # Configurar timezone
    Time.zone = 'America/Sao_Paulo'
    # Verifica se o usuário é machine
    before do
      halt 403, { error: 'Access denied. Machine role required.' }.to_json unless env['current_user_role'] == 'machine'
    end

    # GET /api/billing/overdue - Lista empresas com pagamento atrasado
    get '/overdue' do
      companies = Billing::BillingService.overdue_companies

      result = companies.map do |company|
        {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug,
          email: company.email,
          plan: company.plan,
          billing_day: company.billing_day,
          billing_due_date: company.billing_due_date,
          payment_status: company.payment_status,
          last_payment_date: company.last_payment_date,
          days_overdue: company.billing_due_date ? (Date.today - company.billing_due_date).to_i : 0,
          status: company.status
        }
      end

      { total: result.size, companies: result }.to_json
    end

    # GET /api/billing/pending - Lista empresas com vencimento próximo (próximos 7 dias)
    get '/pending' do
      today = Date.today
      next_week = today + 7

      companies = Billing::BillingService.pending_companies_between(today, next_week)

      result = companies.map do |company|
        {
          id: company.id.to_s,
          name: company.name,
          slug: company.slug,
          email: company.email,
          plan: company.plan,
          billing_day: company.billing_day,
          billing_due_date: company.billing_due_date,
          days_until_due: (company.billing_due_date - today).to_i,
          last_payment_date: company.last_payment_date
        }
      end

      { total: result.size, companies: result }.to_json
    end

    # POST /api/billing/:company_id/mark-paid - Marca pagamento como realizado
    post '/:company_id/mark-paid' do
      company = Billing::BillingService.mark_paid(params[:company_id])

      halt 404, { error: 'Company not found' }.to_json if company.nil?

      {
        message: 'Payment marked as paid successfully',
        company: {
          id: company.id.to_s,
          name: company.name,
          payment_status: company.payment_status,
          last_payment_date: company.last_payment_date,
          billing_due_date: company.billing_due_date,
          status: company.status
        }
      }.to_json
    end

    # POST /api/billing/:company_id/update-billing-day - Atualiza dia de fechamento
    post '/:company_id/update-billing-day' do
      request.body.rewind
      data = JSON.parse(request.body.read)

      billing_day = data['billing_day'].to_i

      halt 400, { error: 'Billing day must be between 1 and 31' }.to_json if billing_day < 1 || billing_day > 31

      company = Billing::BillingService.update_billing_day(params[:company_id], billing_day)

      halt 404, { error: 'Company not found' }.to_json if company.nil?

      {
        message: 'Billing day updated successfully',
        company: {
          id: company.id.to_s,
          name: company.name,
          billing_day: company.billing_day,
          billing_due_date: company.billing_due_date
        }
      }.to_json
    end

    # POST /api/billing/run-check - Executa verificação manual de pagamentos atrasados
    post '/run-check' do
      overdue_count = Billing::BillingService.run_check

      {
        message: 'Payment check completed',
        companies_suspended: overdue_count,
        timestamp: Time.now
      }.to_json
    end

    # GET /api/billing/stats - Estatísticas gerais de faturamento
    get '/stats' do
      Billing::BillingService.stats.to_json
    end
  end
end
