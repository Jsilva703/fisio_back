# frozen_string_literal: true

class MedicalRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  # Informações da Consulta/Evolução
  field :record_type, type: String, default: 'evolution' # anamnesis, evolution, discharge
  field :date, type: String # Data da consulta/evolução (YYYY-MM-DD)
  field :time, type: String # Hora da consulta (HH:MM)

  # Dados Clínicos
  field :chief_complaint, type: String # Queixa principal
  field :history, type: String # História da doença atual / Anamnese
  field :physical_exam, type: String # Exame físico / Avaliação
  field :diagnosis, type: String # Diagnóstico fisioterapêutico
  field :treatment_plan, type: String # Plano de tratamento
  field :evolution, type: String # Evolução do paciente
  field :procedures, type: Array, default: [] # Procedimentos realizados

  # Sinais Vitais (opcional)
  field :vital_signs, type: Hash, default: {
    blood_pressure: '',  # Ex: "120/80"
    heart_rate: '',      # Ex: "72 bpm"
    temperature: '',     # Ex: "36.5°C"
    weight: '',          # Ex: "70 kg"
    height: ''           # Ex: "1.75 m"
  }

  # Testes e Avaliações
  field :tests, type: Array, default: [] # Testes realizados (ex: força muscular, amplitude de movimento)
  field :pain_scale, type: Integer # Escala de dor (0-10)

  # Objetivos e Metas
  field :goals, type: Array, default: [] # Objetivos do tratamento
  field :next_steps, type: String # Próximos passos / Orientações

  # Anexos e Documentos
  field :attachments, type: Array, default: [] # URLs ou referências a arquivos

  # Status e Controle
  field :status, type: String, default: 'open' # open, closed
  field :notes, type: String # Observações gerais

  # Relacionamentos
  belongs_to :patient
  belongs_to :company
  belongs_to :created_by, class_name: 'User', optional: true # Profissional que criou
  belongs_to :appointment, optional: true # Vincula com agendamento se houver

  # Índices
  index({ patient_id: 1, date: -1 })
  index({ company_id: 1, date: -1 })
  index({ created_by_id: 1, date: -1 })
  index({ record_type: 1 })

  # Validações
  validates :patient_id, presence: true
  validates :company_id, presence: true
  validates :date, presence: true
  validates :record_type, inclusion: { in: %w[anamnesis evolution discharge abandonment] }
  validates :status, inclusion: { in: %w[open closed] }
  validates :pain_scale, inclusion: { in: 0..10 }, allow_nil: true

  # Callbacks
  before_validation :set_date_if_blank, on: :create

  # Métodos
  def formatted_date
    return '' unless date.present?

    Date.parse(date).strftime('%d/%m/%Y')
  rescue StandardError
    date
  end

  def is_recent?
    return false unless date.present?

    record_date = Date.parse(date)
    (Date.today - record_date).to_i <= 30 # Últimos 30 dias
  rescue StandardError
    false
  end

  def professional_name
    created_by&.name || 'Sistema'
  end

  def has_attachments?
    attachments.present? && attachments.any?
  end

  private

  def set_date_if_blank
    self.date ||= Date.today.to_s
    self.time ||= Time.now.strftime('%H:%M')
  end
end
