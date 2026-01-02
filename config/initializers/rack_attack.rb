# frozen_string_literal: true

require 'rack/attack'
require 'active_support/cache'

class Rack::Attack
  # Allow local traffic (loopback)
  safelist('allow-localhost') do |req|
    ['127.0.0.1', '::1'].include?(req.ip)
  end

  # Ensure a cache store is configured for Rack::Attack to avoid MissingStoreError
  begin
    Rack::Attack.cache.store ||= ActiveSupport::Cache::MemoryStore.new
  rescue => e
    warn "Rack::Attack cache setup failed: #{e.message}"
  end

  # Allow CORS preflight OPTIONS requests to bypass throttles/blocklists
  safelist('allow preflight options') do |req|
    req.request_method == 'OPTIONS'
  end

  # Throttle requests by IP: 60 requests per minute
  throttle('req/ip', limit: 60, period: 60) do |req|
    req.ip
  end

  # Block abusive user agents
  blocklist('block bad UA') do |req|
    ua = req.user_agent.to_s.downcase
    ua.include?('masscan') || ua.include?('sqlmap') || ua.include?('nikto')
  end

  # Custom response for throttled requests
  self.throttled_response = lambda do |env|
    [429, { 'Content-Type' => 'application/json' }, [{ error: 'Throttle limit reached. Try later.' }.to_json]]
  end
end
