class Appointment

    include Mongoid::Document
    include Mongoid::Timestamps 

    field :patient_name, type: String
    field :patient_phone, type: String
    field :patiente_document, type: String


    field :type, type: String, default: :clinic
    field :address, type: String

    field :appointment_date, type: Time
    field :duration, type: Integer, default: 60

    field :price, type: BigDecimal
    field :payment_status, type: String, default: 'pending' 
    field :status, type: String, default: 'scheduled'

    validates :patient_name, presence: true
    validates :appointment_date, presence: true
    validates :price, presence: true
    validates :patient_phone, presence: true
    validates :patiente_document, presence: true

    validates :address, presence: true, if: -> { type == :home}
end    