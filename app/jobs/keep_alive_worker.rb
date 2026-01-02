# frozen_string_literal: true

require 'net/http'
require 'uri'

class KeepAliveWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'default'

  def perform
    base = ENV['APP_BASE_URL'] || 'https://fisio-back.onrender.com'
    urls = [base, "#{base}/health"]

    urls.each do |u|
      begin
        uri = URI(u)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 5, read_timeout: 5) do |http|
          req = Net::HTTP::Get.new(uri)
          http.request(req)
        end
      rescue => e
        puts "KeepAliveWorker error pinging #{u}: #{e.message}"
      end
    end
  end
end
