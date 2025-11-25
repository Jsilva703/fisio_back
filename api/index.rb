require 'bundler/setup'
Bundler.require

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options]
  end
end

class App < Sinatra::Base
  get '/' do
    content_type :json
    { status: 'API DJM Online na Vercel', env: 'Production' }.to_json
  end
end

run App
