class Professional
  include Mongoid::Document
  include Mongoid::Timestamps

  # ID Sequencial customizado
  field :professional_id, type: Integer # 10, 11, 12, 13...
  
  # Informações Básicas
  field :name, type: String
  field :email, type: String
  field :phone, type: String
  field :cpf, type: String
  field :registration_number, type: String # CRM, CREFITO, etc
  field :specialty, type: String # Fisioterapeuta, Médico, Psicólogo, etc
  field :color, type: String, default: '#3B82F6' # Para visualização na agenda
  field :status, type: String, default: 'active' # active, inactive
  
  # Relacionamentos
  belongs_to :company
  has_many :appointments
  has_many :schedulings
  
  # Índices
  index({ company_id: 1, professional_id: 1 }, { unique: true })
  index({ company_id: 1, status: 1 })
  index({ cpf: 1 })
  
  # Validações
  validates :name, presence: true
  validates :company_id, presence: true
  validates :professional_id, presence: true, uniqueness: { scope: :company_id }
  validates :status, inclusion: { in: ['active', 'inactive'] }
  validates :cpf, uniqueness: { scope: :company_id }, allow_nil: true
  
  # Callbacks
  before_validation :generate_professional_id, on: :create
  
  # Métodos
  def active?
    status == 'active'
  end
  
  def formatted_cpf
    return '' unless cpf.present?
    cpf.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
  end
  
  private
  
  def generate_professional_id
    return if professional_id.present?
    
    # Busca o maior professional_id da empresa
    last_professional = Professional.where(company_id: company_id)
                                     .order_by(professional_id: :desc)
                                     .first
    
    # Se não existe nenhum, começa do 10, senão soma +1
    self.professional_id = last_professional ? last_professional.professional_id + 1 : 10
  end
end
