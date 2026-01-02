# frozen_string_literal: true

class Company
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :slug, type: String
  field :email, type: String
  field :phone, type: String
  field :cnpj, type: String
  field :address, type: String
  field :plan, type: String, default: 'basic' # basic, premium, enterprise
  field :status, type: String, default: 'active' # active, inactive, suspended
  field :max_users, type: Integer, default: 5
  field :settings, type: Hash, default: {}

  # Campos de faturamento
  field :billing_day, type: Integer, default: 1 # Dia do mês para fechamento (1-31)
  field :billing_due_date, type: String # Próxima data de vencimento (formato: YYYY-MM-DD)
  field :payment_status, type: String, default: 'paid' # paid, pending, overdue
  field :last_payment_date, type: String # Última data de pagamento (formato: YYYY-MM-DD)

  # Relacionamentos
  has_many :users
  has_many :appointments
  has_many :schedulings
  has_many :patients
  has_many :medical_records

  # Índices
  index({ slug: 1 }, { unique: true })
  index({ cnpj: 1 }, { unique: true, sparse: true })
  index({ status: 1 })

  # Validações
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :plan, inclusion: { in: %w[basic professional premium enterprise] }
  validates :status, inclusion: { in: %w[active inactive suspended] }
  validates :billing_day, inclusion: { in: 1..31 }, allow_nil: true
  validates :payment_status, inclusion: { in: %w[paid pending overdue] }

  # Callbacks
  before_validation :generate_slug, on: :create

  # Métodos
  def active?
    status == 'active'
  end

  def can_add_user?
    users.count < max_users
  end

  def users_count
    users.count
  end

  def appointments_count
    appointments.count
  end

  def schedulings_count
    schedulings.count
  end

  # Verifica se o pagamento está em dia
  def payment_ok?
    payment_status == 'paid'
  end

  # Verifica se o pagamento está atrasado
  def payment_overdue?
    payment_status == 'overdue'
  end

  # Calcula a próxima data de vencimento com base no billing_day
  def calculate_next_due_date
    return nil unless billing_day

    today = Date.today
    # Se o dia já passou neste mês, pega o próximo mês
    if today.day >= billing_day
      next_month = (today + 30).beginning_of_month
      # Ajusta para o billing_day ou último dia do mês
      last_day = next_month.end_of_month.day
      day = [billing_day, last_day].min
      "#{next_month.year}-#{next_month.month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
    else
      # Pega neste mês
      last_day = today.end_of_month.day
      day = [billing_day, last_day].min
      "#{today.year}-#{today.month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
    end
  end

  # Atualiza a data de vencimento
  def update_due_date!
    self.billing_due_date = calculate_next_due_date
    save
  end

  # Marca pagamento como realizado
  def mark_as_paid!
    self.payment_status = 'paid'
    self.last_payment_date = Date.today.to_s
    self.status = 'active' if status == 'suspended'
    update_due_date!
    save
  end

  # Marca pagamento como atrasado e suspende
  def mark_as_overdue!
    self.payment_status = 'overdue'
    self.status = 'suspended'
    save
  end

  private

  def generate_slug
    return if slug.present?

    base_slug = name.parameterize
    self.slug = base_slug
    counter = 1
    while Company.where(slug: slug).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
