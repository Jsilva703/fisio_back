class Expense
  include Mongoid::Document
  include Mongoid::Timestamps

  # Campos obrigatórios
  field :description, type: String
  field :status, type: String, default: 'active' # Ex: active, inactive, canceled
  field :valor, type: Float
  field :data, type: Date
  field :forma_pagamento, type: String # Ex: pix, cartão no modo geral
  field :category, type: String
  field :external, type: Array, default: []
end