#!/usr/bin/env ruby
# frozen_string_literal: true

require 'httparty'
require 'dotenv'
require 'json'

Dotenv.load

SUPABASE_URL = ENV['SUPABASE_URL']
SERVICE_ROLE_KEY = ENV['SUPABASE_SERVICE_ROLE_KEY']

puts "🚀 Criando bucket 'avatars' no Supabase...\n"

# Criar bucket via API
response = HTTParty.post(
  "#{SUPABASE_URL}/storage/v1/bucket",
  headers: {
    'Authorization' => "Bearer #{SERVICE_ROLE_KEY}",
    'Content-Type' => 'application/json',
    'apikey' => SERVICE_ROLE_KEY
  },
  body: {
    id: 'avatars',
    name: 'avatars',
    public: true,
    file_size_limit: 5242880, # 5MB
    allowed_mime_types: ['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
  }.to_json
)

if response.success?
  puts "✅ Bucket 'avatars' criado com sucesso!"
  puts "\n📋 Detalhes:"
  puts response.body
else
  error_message = response.parsed_response
  if error_message.is_a?(Hash) && error_message['message']&.include?('already exists')
    puts "ℹ️  Bucket 'avatars' já existe!"
  else
    puts "❌ Erro ao criar bucket:"
    puts response.body
    exit 1
  end
end

puts "\n🔧 Configurando políticas de acesso...\n"

# Políticas RLS para o bucket
policies = [
  {
    name: 'SELECT',
    sql: "CREATE POLICY \"Allow public read access\" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');"
  },
  {
    name: 'INSERT',
    sql: "CREATE POLICY \"Allow authenticated uploads\" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars');"
  },
  {
    name: 'DELETE',
    sql: "CREATE POLICY \"Allow authenticated deletes\" ON storage.objects FOR DELETE USING (bucket_id = 'avatars');"
  }
]

policies.each do |policy|
  response = HTTParty.post(
    "#{SUPABASE_URL}/rest/v1/rpc/exec_sql",
    headers: {
      'Authorization' => "Bearer #{SERVICE_ROLE_KEY}",
      'Content-Type' => 'application/json',
      'apikey' => SERVICE_ROLE_KEY,
      'Prefer' => 'return=representation'
    },
    body: { query: policy[:sql] }.to_json
  )
  
  if response.success? || response.code == 409
    puts "✅ Política #{policy[:name]} configurada"
  else
    puts "⚠️  Política #{policy[:name]}: #{response.body}"
  end
end

puts "\n✅ Configuração completa!"
puts "\n📝 URLs públicas dos avatars seguirão o padrão:"
puts "   #{SUPABASE_URL}/storage/v1/object/public/avatars/users/{user_id}/{filename}"
puts "   #{SUPABASE_URL}/storage/v1/object/public/avatars/professionals/{professional_id}/{filename}"
