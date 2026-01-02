require 'rubygems'
require 'bundler/setup'
require 'sidekiq/web'
require 'securerandom'
require 'digest'
require 'rack/session/cookie'
require 'rack/attack'

# Ensure a persistent session secret file exists (created on first run)
session_file = File.expand_path('../.session.key', __dir__)
unless File.exist?(session_file)
  File.write(session_file, SecureRandom.hex(64))
end
session_secret = File.read(session_file).strip

# Enable cookie-based sessions required by Sidekiq Web (CSRF protection)
use Rack::Session::Cookie, secret: session_secret, same_site: :lax, max_age: 86_400

# Load Rack::Attack rules (if present)
begin
  require_relative 'initializers/rack_attack'
  use Rack::Attack
rescue LoadError
  # ignore if not present
end

# Basic HTTP auth for the Sidekiq Web UI. Set SIDEKIQ_WEB_USER and SIDEKIQ_WEB_PASSWORD in env.
web_user = ENV['SIDEKIQ_WEB_USER'] || 'admin'
web_pass = ENV['SIDEKIQ_WEB_PASSWORD'] || 'password'
use Rack::Auth::Basic, 'Sidekiq Web' do |u, p|
  ok_user = Digest::SHA256.hexdigest(u) == Digest::SHA256.hexdigest(web_user)
  ok_pass = Digest::SHA256.hexdigest(p) == Digest::SHA256.hexdigest(web_pass)
  ok_user & ok_pass
end

# Optional: load app environment if needed
begin
  require_relative 'config/environment'
rescue LoadError
  # ignore if environment not loadable here
end

run Sidekiq::Web
