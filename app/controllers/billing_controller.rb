# Controller para gerenciar faturamento
# Apenas o role 'machine' pode acessar estas rotas

require 'sinatra/base'
require 'json'
require 'active_support/all'
require_relative '../models/company'

class BillingController < Sinatra::Base
  # Configurar timezone
  Time.zone = 'America/Sao_Paulo'
  # Verifica se o usuário é machine
  before do
    halt 403, { error: 'Access denied. Machine role required.' }.to_json unless env['current_user_role'] == 'machine'
  end
  
  # GET /api/billing/overdue - Lista empresas com pagamento atrasado
  get '/overdue' do
    companies = Company.where(payment_status: 'overdue')
    
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
    
    companies = Company.where(
      status: 'active',
      payment_status: 'paid',
      :billing_due_date.gte => today,
      :billing_due_date.lte => next_week
    )
    
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
    company = Company.find(params[:company_id])
    
    if company.nil?
      halt 404, { error: 'Company not found' }.to_json
    end
    
    company.mark_as_paid!
    
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
    
    company = Company.find(params[:company_id])
    
    if company.nil?
      halt 404, { error: 'Company not found' }.to_json
    end
    
    billing_day = data['billing_day'].to_i
    
    if billing_day < 1 || billing_day > 31
      halt 400, { error: 'Billing day must be between 1 and 31' }.to_json
    end
    
    company.billing_day = billing_day
    company.update_due_date!
    
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
    require_relative '../jobs/check_overdue_payments'
    
    overdue_count = CheckOverduePayments.run
    
    {
      message: 'Payment check completed',
      companies_suspended: overdue_count,
      timestamp: Time.now
    }.to_json
  end
  
  # GET /api/billing/stats - Estatísticas gerais de faturamento
  get '/stats' do
    total_companies = Company.count
    paid = Company.where(payment_status: 'paid').count
    pending = Company.where(payment_status: 'pending').count
    overdue = Company.where(payment_status: 'overdue').count
    
    # Empresas com vencimento nos próximos 7 dias
    today = Date.today
    next_week = today + 7
    due_soon = Company.where(
      status: 'active',
      payment_status: 'paid',
      :billing_due_date.gte => today,
      :billing_due_date.lte => next_week
    ).count
    
    {
      total_companies: total_companies,
      payment_status: {
        paid: paid,
        pending: pending,
        overdue: overdue
      },
      due_soon_7_days: due_soon,
      suspended_by_payment: Company.where(status: 'suspended', payment_status: 'overdue').count
    }.to_json
  end
end
