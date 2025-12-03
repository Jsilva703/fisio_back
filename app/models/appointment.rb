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
    field :procedure, type: String # Tipo de procedimento/consulta
    
    field :company_id, type: BSON::ObjectId

    # Relacionamentos
    belongs_to :company
    belongs_to :patient, optional: true

    # Índices
    index({ company_id: 1 })
    index({ company_id: 1, appointment_date: -1 })

    validates :patient_name, presence: true
    validates :appointment_date, presence: true
    validates :price, presence: true
    validates :patient_phone, presence: true
    validates :patiente_document, presence: true
    validates :company_id, presence: true

    validates :address, presence: true, if: -> { type == :home}

    # Métodos auxiliares
    def date
      appointment_date&.in_time_zone&.to_date&.to_s
    end

    def time
      appointment_date&.in_time_zone&.strftime('%H:%M')
    end

    def formatted_date
      appointment_date&.in_time_zone&.strftime('%d/%m/%Y às %H:%M')
    end
end    