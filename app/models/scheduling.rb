class Scheduling

    include Mongoid::Document
    include Mongoid::Timestamps

    field :date, type: Date
    field :slots, type: Array, default: []
    field :enabled, type: Integer, default: 0 # 0 = disponivel 1 = Ocupado 2 = fechada
    field :company_id, type: BSON::ObjectId

    # Relacionamentos
    belongs_to :company

    # Índices
    index({ company_id: 1, date: 1 }, { unique: true })

    validates :date, presence: true
    validates :company_id, presence: true
    validates :date, uniqueness: { scope: :company_id, message: 'já existe para esta empresa' }

    def reserve_slot(slot)
        result = self.class.collection.update_one(
            { _id: self.id, slots: slot },
            { '$pull' => { slots: slot } }
        )
        result.modified_count > 0
    end

    def release_slot(slot)
        self.class.collection.update_one(
            { _id: self.id },
            { '$push' => { slots: slot } }
        )
    end
end