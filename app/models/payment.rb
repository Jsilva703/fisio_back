# frozen_string_literal: true

class Payment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :external_id, type: String
  field :status, type: String
  field :amount, type: Float
  field :raw, type: Hash

  index({ external_id: 1 })
  validates :external_id, presence: true
end
