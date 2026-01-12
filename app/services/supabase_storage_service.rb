# frozen_string_literal: true

require 'httparty'
require 'securerandom'

# Serviço para gerenciar upload de arquivos no Supabase Storage
class SupabaseStorageService
  include HTTParty
  base_uri SUPABASE_URL

  BUCKET_NAME = 'avatars'
  MAX_FILE_SIZE = 5 * 1024 * 1024 # 5MB
  ALLOWED_TYPES = %w[image/jpeg image/jpg image/png image/webp].freeze

  class << self
    # Upload de arquivo para o Supabase Storage
    # @param file [Hash] Hash com dados do arquivo (tempfile, type, filename)
    # @param folder [String] Pasta dentro do bucket (ex: 'users', 'professionals')
    # @param identifier [String] Identificador único (ex: user_id, professional_id)
    # @return [Hash] { success: Boolean, url: String, error: String }
    def upload(file:, folder:, identifier:)
      validate_file!(file)

      # Gera nome único para o arquivo
      extension = File.extname(file[:filename])
      filename = "#{folder}/#{identifier}/#{SecureRandom.uuid}#{extension}"
      
      file_content = file[:tempfile].read
      
      response = post(
        "/storage/v1/object/#{BUCKET_NAME}/#{filename}",
        headers: headers(file[:type]),
        body: file_content
      )

      if response.success?
        public_url = get_public_url(filename)
        { success: true, url: public_url }
      else
        { success: false, error: response.parsed_response['message'] || 'Erro ao fazer upload' }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end

    # Remove arquivo do Supabase Storage
    # @param file_path [String] Caminho do arquivo no bucket
    # @return [Hash] { success: Boolean, error: String }
    def delete(file_path:)
      return { success: false, error: 'URL inválida' } unless file_path

      # Extrai o caminho do arquivo da URL pública
      path = extract_path_from_url(file_path)
      return { success: false, error: 'Caminho inválido' } unless path

      response = HTTParty.delete(
        "#{SUPABASE_URL}/storage/v1/object/#{BUCKET_NAME}/#{path}",
        headers: {
          'Authorization' => "Bearer #{SUPABASE_SERVICE_ROLE_KEY}",
          'apikey' => SUPABASE_SERVICE_ROLE_KEY
        }
      )

      if response.success?
        { success: true }
      else
        { success: false, error: response.parsed_response['message'] || 'Erro ao deletar arquivo' }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end

    # Gera URL pública do arquivo
    # @param file_path [String] Caminho do arquivo no bucket
    # @return [String] URL pública
    def get_public_url(file_path)
      "#{SUPABASE_URL}/storage/v1/object/public/#{BUCKET_NAME}/#{file_path}"
    end

    private

    def headers(content_type = 'application/json')
      {
        'Authorization' => "Bearer #{SUPABASE_SERVICE_ROLE_KEY}",
        'Content-Type' => content_type,
        'apikey' => SUPABASE_SERVICE_ROLE_KEY
      }
    end

    def validate_file!(file)
      raise 'Arquivo não fornecido' unless file && file[:tempfile]
      raise 'Tipo de arquivo não permitido' unless ALLOWED_TYPES.include?(file[:type])
      
      file_size = file[:tempfile].size
      raise "Arquivo muito grande (máximo #{MAX_FILE_SIZE / 1024 / 1024}MB)" if file_size > MAX_FILE_SIZE
    end

    def extract_path_from_url(url)
      return nil unless url.include?(BUCKET_NAME)
      
      # Extrai o caminho após /public/avatars/
      match = url.match(%r{/public/#{BUCKET_NAME}/(.+)})
      match ? match[1] : nil
    end
  end
end
