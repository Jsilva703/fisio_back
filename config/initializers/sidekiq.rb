# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-scheduler'
require 'yaml'

Sidekiq.configure_server do |config|
  schedule_file = File.expand_path('../../config/sidekiq.yml', __dir__)

  if File.exist?(schedule_file)
    begin
      yml = YAML.load_file(schedule_file)
      schedule = yml['schedule'] || yml[:schedule]
      if schedule && schedule.is_a?(Hash)
        Sidekiq::Scheduler.dynamic = true
        Sidekiq::Scheduler.reload_schedule!(schedule)
        puts "Loaded sidekiq schedule: ", schedule.keys
      end
    rescue => e
      puts "Error loading sidekiq schedule: #{e.message}"
    end
  end
end

# Configure Redis connection explicitly from REDIS_URL for server and client
redis_url = ENV['REDIS_URL'] || 'redis://127.0.0.1:6379/0'

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
