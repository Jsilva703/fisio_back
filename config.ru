# encoding: UTF-8
require 'bundler/setup'
Bundler.require

# --- ADICIONA ESTE BLOCO ---
configure do
  disable :protection
end
# ---------------------------

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
  end
end

get '/' do
  content_type :json
  { status: 'API DJM Online na Vercel', env: 'Production' }.to_json
end

# Adiciona esta rota para o teu teste funcionar
get '/health' do
  content_type :json
  { status: 'Saudavel', timestamp: Time.now.to_s }.to_json
end

run Sinatra::Application