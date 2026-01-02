# frozen_string_literal: true

class Scheduling
  include Mongoid::Document
  include Mongoid::Timestamps

  field :date, type: Date
  field :slots, type: Array, default: []
  field :enabled, type: Integer, default: 0 # 0 = disponivel 1 = Ocupado 2 = fechada 3 = feriado
  field :company_id, type: BSON::ObjectId
  field :professional_id, type: Integer # Agenda vinculada a um profissional específico
  field :room_id, type: Integer # Agenda vinculada a uma sala específica

  # Relacionamentos
  belongs_to :company
  belongs_to :professional, optional: true, foreign_key: :professional_id, primary_key: :professional_id
  belongs_to :room, optional: true, foreign_key: :room_id, primary_key: :room_id

  # Índices
  index({ company_id: 1, date: 1 }, { unique: true })
  index({ company_id: 1, professional_id: 1, date: 1 })
  index({ company_id: 1, room_id: 1, date: 1 })

  validates :date, presence: true
  validates :company_id, presence: true
  validates :date, uniqueness: { scope: :company_id, message: 'já existe para esta empresa' }

  def reserve_slot(slot)
    result = self.class.collection.update_one(
      { _id: id, slots: slot },
      { '$pull' => { slots: slot } }
    )
    result.modified_count.positive?
  end

  def release_slot(slot)
    self.class.collection.update_one(
      { _id: id },
      { '$push' => { slots: slot } }
    )
  end
end
