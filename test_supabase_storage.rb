#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv'
Dotenv.load

require_relative 'config/initializers/supabase'
require_relative 'app/services/supabase_storage_service'

puts "🧪 Testando Supabase Storage Service...\n\n"

# Criar um arquivo de teste (imagem fake PNG de 1x1 pixel)
test_image_data = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"

require 'tempfile'
file = Tempfile.new(['test_avatar', '.png'])
file.write(test_image_data)
file.rewind

file_hash = {
  tempfile: file,
  type: 'image/png',
  filename: 'test_avatar.png'
}

puts "📤 1. Testando UPLOAD..."
result = SupabaseStorageService.upload(
  file: file_hash,
  folder: 'users',
  identifier: 'test_user_123'
)

if result[:success]
  puts "   ✅ Upload realizado com sucesso!"
  puts "   📍 URL: #{result[:url]}"
  avatar_url = result[:url]
  
  puts "\n📥 2. Testando acesso à URL pública..."
  require 'net/http'
  uri = URI(avatar_url)
  response = Net::HTTP.get_response(uri)
  
  if response.code == '200'
    puts "   ✅ Imagem acessível publicamente!"
  else
    puts "   ❌ Erro ao acessar imagem: #{response.code}"
  end
  
  puts "\n🗑️  3. Testando DELETE..."
  delete_result = SupabaseStorageService.delete(file_path: avatar_url)
  
  if delete_result[:success]
    puts "   ✅ Arquivo deletado com sucesso!"
  else
    puts "   ❌ Erro ao deletar: #{delete_result[:error]}"
  end
else
  puts "   ❌ Erro no upload: #{result[:error]}"
end

file.close
file.unlink

puts "\n✨ Teste finalizado!"
