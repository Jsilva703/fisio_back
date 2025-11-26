class Scheduling

    include Mongoid::Document
    include Mongoid::Timestamps

    field :date, type: Date
    field :slots, type: Array, default: []
    field :enabled, type: Integer, default: 0 # 0 = disponivel 1 = Ocupado 2 = fechada

    validates :date, presence: true, uniqueness: true

    index({date: 1}, {unique: true})
end