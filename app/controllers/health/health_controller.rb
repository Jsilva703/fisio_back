# frozen_string_literal: true

module Health
  class HealthController
    def self.check
      {
        status: 'OK',
        message: 'API DJM está funcionando perfeitamente!',
        timestamp: Time.now.iso8601,
        environment: ENV['RACK_ENV'] || 'development'
      }
    end

    def self.info
      {
        name: 'API DJM',
        version: '1.0.0',
        description: 'API para gerenciamento de fisioterapia',
        uptime: 'Sistema em operação',
        created_at: '2025-11-25'
      }
    end
  end
end
