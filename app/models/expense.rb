# frozen_string_literal: true

class Expense
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: Date
  field :category, type: String
  field :amount, type: BigDecimal
  field :description, type: String
  field :company_id, type: String
  field :created_by, type: String

  validates :date, :category, :amount, :company_id, presence: true

  def as_json(_opts = {})
    {
      id: id.to_s,
      date: date&.iso8601,
      category: category,
      amount: amount ? BigDecimal(amount.to_s).to_f : nil,
      description: description,
      company_id: company_id,
      created_by: created_by,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end
end