# frozen_string_literal: true

# Serviço simples para health
module Health
  class HealthService
    def self.status
      { status: 'OK', timestamp: Time.now }
    end
  end
end
