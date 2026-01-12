# frozen_string_literal: true

# Configuração do Supabase Storage
SUPABASE_URL = ENV['SUPABASE_URL'] || 'https://ikxukvsxuokmnlcxffky.supabase.co'
SUPABASE_SERVICE_ROLE_KEY = ENV['SUPABASE_SERVICE_ROLE_KEY']

if SUPABASE_SERVICE_ROLE_KEY.nil?
  puts '⚠️  AVISO: SUPABASE_SERVICE_ROLE_KEY não configurada'
end
