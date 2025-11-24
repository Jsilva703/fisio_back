require 'bundler/setup'
Bundler.require

# Configuração de Segurança (CORS)
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
  end
end

# --- A CORREÇÃO ESTÁ AQUI ---
# Primeiro definimos a rota
get '/' do
  content_type :json
  { status: 'API DJM Online 🚀', versao: '1.0.0' }.to_json
end

# Depois mandamos rodar a aplicação (sem o bloco do...end)
run Sinatra::Application