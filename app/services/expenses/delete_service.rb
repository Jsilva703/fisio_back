# frozen_string_literal: true

module Expenses
  class DeleteService
    def self.call(id, env)
      company_id = env['current_company_id']
      expense = Expense.where(id: id, company_id: company_id).first
      return { status: 404, body: { error: 'Despesa não encontrada' } } if expense.nil?

      if expense.destroy
        { status: 200, body: { status: 'success', mensagem: 'Despesa deletada' } }
      else
        { status: 422, body: { error: 'Erro ao deletar' } }
      end
    rescue StandardError => e
      { status: 500, body: { error: 'Erro ao deletar', mensagem: e.message } }
    end
  end
end
