class Room
  include Mongoid::Document
  include Mongoid::Timestamps

  # ID Sequencial customizado
  field :room_id, type: Integer # 10, 11, 12, 13...
  
  # Informações Básicas
  field :name, type: String # "Sala 1", "Consultório A"
  field :description, type: String
  field :capacity, type: Integer, default: 1
  field :color, type: String, default: '#10B981' # Para visualização na agenda
  field :status, type: String, default: 'active' # active, inactive
  
  # Relacionamentos
  belongs_to :company
  has_many :appointments
  has_many :schedulings
  
  # Índices
  index({ company_id: 1, room_id: 1 }, { unique: true })
  index({ company_id: 1, status: 1 })
  
  # Validações
  validates :name, presence: true
  validates :company_id, presence: true
  validates :room_id, presence: true, uniqueness: { scope: :company_id }
  validates :status, inclusion: { in: ['active', 'inactive'] }
  validates :capacity, numericality: { greater_than: 0 }, allow_nil: true
  
  # Callbacks
  before_validation :generate_room_id, on: :create
  
  # Métodos
  def active?
    status == 'active'
  end
  
  def available?
    active? && capacity.to_i > 0
  end
  
  private
  
  def generate_room_id
    return if room_id.present?
    
    # Busca o maior room_id da empresa
    last_room = Room.where(company_id: company_id)
                    .order_by(room_id: :desc)
                    .first
    
    # Se não existe nenhum, começa do 10, senão soma +1
    self.room_id = last_room ? last_room.room_id + 1 : 10
  end
end
