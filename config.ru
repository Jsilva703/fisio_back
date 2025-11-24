require 'bundler/setup'
Bundler.require

# TEM DE ESTAR COMENTADO PARA ESSE TESTE
# Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
  end
end

# Define a rota
get '/' do
  content_type :json
  { status: 'API DJM Online na Vercel 🚀', env: 'Production' }.to_json
end

# Roda a app
run Sinatra::Application