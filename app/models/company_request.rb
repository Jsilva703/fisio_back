# frozen_string_literal: true

class CompanyRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :slug, type: String
  field :email, type: String
  field :phone, type: String
  field :cnpj, type: String
  # normalized document (cpf or cnpj digits only)
  field :document, type: String
  # 'cpf' or 'cnpj' when known
  field :document_type, type: String
  field :address, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :zip, type: String
  field :notes, type: String
  field :referrer, type: String
  field :utm_source, type: String
  field :utm_campaign, type: String
  field :plan, type: String
  field :status, type: String, default: 'pending' # pending, reviewed, rejected
  field :max_users, type: Integer, default: 5
  field :settings, type: Hash, default: {}

  index({ email: 1 })
  index({ document: 1 })
  index({ status: 1 })

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :plan, presence: true
end
