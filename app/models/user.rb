# frozen_string_literal: true

require 'bcrypt'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  field :name, type: String
  field :email, type: String
  field :password_digest, type: String
  field :role, type: String, default: 'user' # user, admin, gestor, atendente, machine
  field :phone, type: String
  field :status, type: String, default: 'active' # active, inactive
  field :company_id, type: BSON::ObjectId
  field :avatar_url, type: String

  # Relacionamentos
  belongs_to :company, optional: true

  # Índices
  index({ email: 1 }, { unique: true })
  index({ company_id: 1 })

  # Validações
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password_digest, presence: true
  validates :role, inclusion: { in: %w[user admin gestor atendente machine], message: '%<value>s não é um role válido' }
  validates :status, inclusion: { in: %w[active inactive] }
  validates :company_id, presence: true, unless: -> { role == 'machine' }

  # Método para definir a senha (criptografa automaticamente)
  def password=(new_password)
    @password = new_password
    self.password_digest = BCrypt::Password.create(new_password)
  end

  # Método para verificar a senha
  def authenticate(password)
    BCrypt::Password.new(password_digest) == password
  end

  def admin?
    role == 'admin'
  end

  def gestor?
    role == 'gestor'
  end

  def atendente?
    role == 'atendente'
  end

  # Retorna dados do usuário sem a senha
  def as_json(options = {})
    super(options.merge(except: [:password_digest]))
  end
end
