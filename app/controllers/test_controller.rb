class TestController
  def self.welcome
    {
      status: 'success',
      message: 'Bem-vindo à API DJM!',
      data: {
        welcome_text: 'Esta é uma API de teste para fisioterapia',
        endpoints: [
          { method: 'GET', path: '/', description: 'Raiz da API' },
          { method: 'GET', path: '/health', description: 'Status de saúde da API' },
          { method: 'GET', path: '/api/info', description: 'Informações da API' },
          { method: 'GET', path: '/api/test', description: 'Rota de teste' }
        ]
      }
    }
  end

  def self.test_message
    {
      status: 'success',
      message: 'Teste de rota funcionando!',
      data: {
        timestamp: Time.now.iso8601,
        random_number: rand(1..100),
        test_array: ['item1', 'item2', 'item3']
      }
    }
  end
end
