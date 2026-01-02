# frozen_string_literal: true

# Serviços para rotas de teste
module Test
  class TestService
    def self.welcome
      Test::TestController.welcome
    end
  end
end
