# frozen_string_literal: true

class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :subscription_id, type: BSON::ObjectId
  field :company_id, type: BSON::ObjectId
  field :amount_cents, type: Integer
  field :status, type: String, default: 'pending' # pending, paid, failed
  field :due_date, type: Date
  field :external_id, type: String
  field :metadata, type: Hash, default: {}

  index({ subscription_id: 1 })
  index({ company_id: 1 })
end
