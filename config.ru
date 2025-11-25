# encoding: UTF-8
require 'bundler/setup'
Bundler.require

# TEM DE ESTAR COMENTADO PARA ESTE TESTE
# Mongoid.load!(File.join(File.dirname(__FILE__), 'config', 'mongoid.yml'))

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

run Sinatra::Application