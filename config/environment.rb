# frozen_string_literal: true
# frozen_string_literal: true

# Arquivo de ambiente para jobs e scripts
require 'bundler/setup'
require 'dotenv'
Dotenv.load

Bundler.require

require 'active_support/time'
# Ensure Time.zone is a TimeZone object for scripts/jobs
Time.zone ||= ActiveSupport::TimeZone['America/Sao_Paulo']

# Carregar Configuração do Banco
Mongoid.load!(File.join(File.dirname(__FILE__), 'mongoid.yml'))

# Carregar Models
require_relative '../app/models/company'
require_relative '../app/models/user'
require_relative '../app/models/appointment'
require_relative '../app/models/scheduling'
require_relative 'initializers/sidekiq'
