# frozen_string_literal: true

class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps

  field :company_id, type: BSON::ObjectId
  field :user_id, type: String
  field :plan_id, type: String
  field :price_cents, type: Integer
  field :status, type: String, default: 'pending' # pending, active, canceled, failed
  field :external_reference, type: String
  field :metadata, type: Hash, default: {}

  index({ company_id: 1 })
  index({ user_id: 1 })
  index({ external_reference: 1 })

  validates :company_id, presence: true
  validates :plan_id, presence: true
end
