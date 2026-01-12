# frozen_string_literal: true

require_relative '../../middleware/auth_middleware'
require_relative '../../services/supabase_storage_service'

module Avatars
  class AvatarsController < Sinatra::Base
    # Upload avatar do usuário
    # POST /api/users/:id/avatar
    post '/api/users/:id/avatar' do
      content_type :json

      user_id = params[:id]
      
      # Verificar autenticação
      current_user_id = env['current_user_id']
      unless current_user_id
        halt 401, { error: 'Não autenticado' }.to_json
      end

      current_user = User.find(current_user_id)

      # Qualquer usuário pode atualizar sua própria foto
      # Admin pode atualizar de qualquer um
      unless current_user.id.to_s == user_id || current_user.admin?
        halt 403, { error: 'Você só pode atualizar seu próprio avatar' }.to_json
      end

      user = User.find(user_id)

      unless params[:file]
        halt 400, { error: 'Nenhum arquivo foi enviado' }.to_json
      end

      # Remove avatar anterior se existir
      if user.avatar_url.present?
        SupabaseStorageService.delete(file_path: user.avatar_url)
      end

      # Upload do novo avatar
      result = SupabaseStorageService.upload(
        file: params[:file],
        folder: 'users',
        identifier: user.id.to_s
      )

      if result[:success]
        user.update!(avatar_url: result[:url])
        status 200
        {
          message: 'Avatar atualizado com sucesso',
          avatar_url: result[:url],
          user: user.as_json
        }.to_json
      else
        halt 400, { error: result[:error] }.to_json
      end
    rescue Mongoid::Errors::DocumentNotFound
      halt 404, { error: 'Usuário não encontrado' }.to_json
    rescue StandardError => e
      halt 500, { error: "Erro ao fazer upload: #{e.message}" }.to_json
    end

    # Remove avatar do usuário
    # DELETE /api/users/:id/avatar
    delete '/api/users/:id/avatar' do
      content_type :json

      user_id = params[:id]
      
      # Verificar autenticação
      current_user_id = env['current_user_id']
      unless current_user_id
        halt 401, { error: 'Não autenticado' }.to_json
      end

      current_user = User.find(current_user_id)

      # Qualquer usuário pode remover sua própria foto
      # Admin pode remover de qualquer um
      unless current_user.id.to_s == user_id || current_user.admin?
        halt 403, { error: 'Você só pode remover seu próprio avatar' }.to_json
      end

      user = User.find(user_id)

      if user.avatar_url.blank?
        halt 400, { error: 'Usuário não possui avatar' }.to_json
      end

      # Remove do Supabase
      result = SupabaseStorageService.delete(file_path: user.avatar_url)

      if result[:success]
        user.update!(avatar_url: nil)
        status 200
        { message: 'Avatar removido com sucesso' }.to_json
      else
        halt 400, { error: result[:error] }.to_json
      end
    rescue Mongoid::Errors::DocumentNotFound
      halt 404, { error: 'Usuário não encontrado' }.to_json
    rescue StandardError => e
      halt 500, { error: "Erro ao remover avatar: #{e.message}" }.to_json
    end

    # Upload avatar do profissional
    # POST /api/professionals/:id/avatar
    post '/api/professionals/:id/avatar' do
      content_type :json

      professional_id = params[:id]
      
      # Verificar autenticação
      current_user_id = env['current_user_id']
      unless current_user_id
        halt 401, { error: 'Não autenticado' }.to_json
      end

      current_user = User.find(current_user_id)
      professional = Professional.find(professional_id)

      # Verificar permissão (mesma empresa ou admin)
      unless current_user.admin? || current_user.company_id == professional.company_id
        halt 403, { error: 'Sem permissão para atualizar este avatar' }.to_json
      end

      unless params[:file]
        halt 400, { error: 'Nenhum arquivo foi enviado' }.to_json
      end

      # Remove avatar anterior se existir
      if professional.avatar_url.present?
        SupabaseStorageService.delete(file_path: professional.avatar_url)
      end

      # Upload do novo avatar
      result = SupabaseStorageService.upload(
        file: params[:file],
        folder: 'professionals',
        identifier: professional.id.to_s
      )

      if result[:success]
        professional.update!(avatar_url: result[:url])
        status 200
        {
          message: 'Avatar atualizado com sucesso',
          avatar_url: result[:url],
          professional: professional.as_json
        }.to_json
      else
        halt 400, { error: result[:error] }.to_json
      end
    rescue Mongoid::Errors::DocumentNotFound
      halt 404, { error: 'Profissional não encontrado' }.to_json
    rescue StandardError => e
      halt 500, { error: "Erro ao fazer upload: #{e.message}" }.to_json
    end

    # Remove avatar do profissional
    # DELETE /api/professionals/:id/avatar
    delete '/api/professionals/:id/avatar' do
      content_type :json

      professional_id = params[:id]
      
      # Verificar autenticação
      current_user_id = env['current_user_id']
      unless current_user_id
        halt 401, { error: 'Não autenticado' }.to_json
      end

      current_user = User.find(current_user_id)
      professional = Professional.find(professional_id)

      # Verificar permissão (mesma empresa ou admin)
      unless current_user.admin? || current_user.company_id == professional.company_id
        halt 403, { error: 'Sem permissão para remover este avatar' }.to_json
      end

      if professional.avatar_url.blank?
        halt 400, { error: 'Profissional não possui avatar' }.to_json
      end

      # Remove do Supabase
      result = SupabaseStorageService.delete(file_path: professional.avatar_url)

      if result[:success]
        professional.update!(avatar_url: nil)
        status 200
        { message: 'Avatar removido com sucesso' }.to_json
      else
        halt 400, { error: result[:error] }.to_json
      end
    rescue Mongoid::Errors::DocumentNotFound
      halt 404, { error: 'Profissional não encontrado' }.to_json
    rescue StandardError => e
      halt 500, { error: "Erro ao remover avatar: #{e.message}" }.to_json
    end
  end
end
