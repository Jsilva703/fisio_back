require 'bcrypt'

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include BCrypt

  field :name, type: String
  field :email, type: String
  field :password_digest, type: String
  field :role, type: String, default: 'user' # user, admin

  # Índices
  index({ email: 1 }, { unique: true })

  # Validações
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password_digest, presence: true

  # Método para definir a senha (criptografa automaticamente)
  def password=(new_password)
    @password = new_password
    self.password_digest = BCrypt::Password.create(new_password)
  end

  # Método para verificar a senha
  def authenticate(password)
    BCrypt::Password.new(password_digest) == password
  end

  # Retorna dados do usuário sem a senha
  def as_json(options = {})
    super(options.merge(except: [:password_digest]))
  end
end
