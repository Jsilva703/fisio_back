class Patient
  include Mongoid::Document
  include Mongoid::Timestamps

  # Dados Pessoais
  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :cpf, type: String
  field :rg, type: String
  field :birth_date, type: String # Formato: YYYY-MM-DD
  field :gender, type: String # male, female, other
  
  # Endereço
  field :address, type: Hash, default: {
    street: '',
    number: '',
    complement: '',
    neighborhood: '',
    city: '',
    state: '',
    zip_code: ''
  }
  
  # Informações Médicas Básicas
  field :blood_type, type: String # A+, A-, B+, B-, AB+, AB-, O+, O-
  field :allergies, type: Array, default: []
  field :medications, type: Array, default: []
  field :health_insurance, type: Hash, default: {
    provider: '',
    plan: '',
    card_number: ''
  }
  
  # Contato de Emergência
  field :emergency_contact, type: Hash, default: {
    name: '',
    relationship: '',
    phone: ''
  }
  
  # Informações Administrativas
  field :status, type: String, default: 'active' # active, inactive
  field :notes, type: String # Observações gerais
  field :source, type: String, default: 'manual' # manual, online_booking, referral
  
  # Relacionamentos
  belongs_to :company
  has_many :appointments
  has_many :medical_records
  
  # Índices
  index({ company_id: 1, cpf: 1 }, { unique: true, sparse: true })
  index({ company_id: 1, email: 1 })
  index({ company_id: 1, phone: 1 })
  index({ company_id: 1, name: 1 })
  index({ company_id: 1, status: 1 })
  
  # Validações
  validates :name, presence: true
  validates :phone, presence: true
  validates :company_id, presence: true
  validates :gender, inclusion: { in: ['male', 'female', 'other'] }, allow_nil: true
  validates :status, inclusion: { in: ['active', 'inactive'] }
  validates :blood_type, inclusion: { 
    in: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'] 
  }, allow_nil: true
  
  # Validação customizada para CPF único por empresa
  validate :cpf_unique_per_company, if: -> { cpf.present? }
  
  # Métodos
  def age
    return nil unless birth_date.present?
    
    birth = Date.parse(birth_date)
    today = Date.today
    age = today.year - birth.year
    age -= 1 if today < birth.next_year(age)
    age
  rescue
    nil
  end
  
  def full_address
    addr = address
    return '' if addr.blank?
    
    [
      "#{addr['street']}, #{addr['number']}",
      addr['complement'],
      addr['neighborhood'],
      "#{addr['city']}/#{addr['state']}",
      "CEP: #{addr['zip_code']}"
    ].reject(&:blank?).join(' - ')
  end
  
  def active?
    status == 'active'
  end
  
  def has_health_insurance?
    health_insurance.present? && health_insurance['provider'].present?
  end
  
  def total_appointments
    appointments.count
  end
  
  def last_appointment
    appointments.order_by(date: :desc).first
  end
  
  private
  
  def cpf_unique_per_company
    existing = Patient.where(
      company_id: company_id,
      cpf: cpf,
      :id.ne => id
    ).first
    
    if existing
      errors.add(:cpf, 'já está cadastrado para outro paciente nesta empresa')
    end
  end
end
