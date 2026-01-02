# frozen_string_literal: true

# Serviços relacionados a faturamento
module Billing
  class BillingService
    def self.overdue_companies
      Company.where(payment_status: 'overdue')
    end

    def self.pending_companies_between(from_date, to_date)
      Company.where(
        status: 'active',
        payment_status: 'paid',
        :billing_due_date.gte => from_date,
        :billing_due_date.lte => to_date
      )
    end

    def self.mark_paid(company_id)
      company = Company.find(company_id)
      return nil unless company

      company.mark_as_paid!
      company
    end

    def self.update_billing_day(company_id, billing_day)
      company = Company.find(company_id)
      return nil unless company

      company.billing_day = billing_day
      company.update_due_date!
      company
    end

    def self.run_check
      require_relative '../../jobs/check_overdue_payments'
      CheckOverduePayments.run
    end

    def self.stats
      total_companies = Company.count
      paid = Company.where(payment_status: 'paid').count
      pending = Company.where(payment_status: 'pending').count
      overdue = Company.where(payment_status: 'overdue').count

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
        payment_status: { paid: paid, pending: pending, overdue: overdue },
        due_soon_7_days: due_soon,
        suspended_by_payment: Company.where(status: 'suspended', payment_status: 'overdue').count
      }
    end
  end
end
