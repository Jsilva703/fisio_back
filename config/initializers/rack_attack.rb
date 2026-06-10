# frozen_string_literal: true

require 'rack/attack'
require 'active_support/cache'
require 'active_support/cache/redis_cache_store'

class Rack::Attack
  # Allow local traffic (loopback)
  safelist('allow-localhost') do |req|
    ['127.0.0.1', '::1'].include?(req.ip)
  end

  # Ensure a cache store is configured for Rack::Attack to avoid MissingStoreError
  begin
    Rack::Attack.cache.store ||= if ENV['REDIS_URL'].to_s.empty?
                                   ActiveSupport::Cache::MemoryStore.new
                                 else
                                   ActiveSupport::Cache::RedisCacheStore.new(url: ENV['REDIS_URL'])
                                 end
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

  throttle('auth/ip', limit: 10, period: 60) do |req|
    req.ip if req.post? && req.path.start_with?('/api/auth')
  end

  throttle('public-signup/ip', limit: 5, period: 300) do |req|
    req.ip if req.post? && req.path.start_with?('/api/public/signup_company')
  end

  throttle('public-booking/ip', limit: 10, period: 60) do |req|
    req.ip if req.post? && req.path.include?('/book') && req.path.start_with?('/api/public/booking')
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
