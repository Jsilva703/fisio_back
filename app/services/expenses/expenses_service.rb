# frozen_string_literal: true

module Expenses
  class ExpensesService
    def self.create(company_id, params_data, created_by = nil)
      expense = Expense.new(
        date: params_data['date'] ? Date.parse(params_data['date'].to_s) : nil,
        category: params_data['category'],
        amount: BigDecimal(params_data['amount'].to_s),
        description: params_data['description'],
        company_id: company_id,
        created_by: created_by
      )

      raise StandardError, expense.errors.full_messages.join(', ') unless expense.save

      expense
    end

    def self.list_by_company(company_id, limit = 100)
      Expense.where(company_id: company_id).desc(:date).limit(limit)
    end
  end
end
