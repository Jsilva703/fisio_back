# frozen_string_literal: true

require 'mercadopago'

class MercadoPagoService
  def self.create_payment_preference(title:, quantity:, unit_price:, payer_email:)
    sdk = Mercadopago::SDK.new(ENV['MERCADO_PAGO_ACCESS_TOKEN'] || 'APP_USR-1440864513720451-122917-779ce32465e0184136575fc697f4b86a-3100407366')

    preference_data = {
      items: [
        {
          title: title,
          quantity: quantity,
          currency_id: 'BRL',
          unit_price: unit_price
        }
      ],
      payer: {
        email: payer_email
      }
    }

    response = sdk.preference.create(preference_data)
    if response[:status] == 201
      puts "Link de pagamento: #{response[:response]['init_point']}"
      response[:response]
    else
      puts "Erro ao criar preferência: #{response.inspect}"
      nil
    end
  end
end

# Teste manual (roda: ruby app/services/mercado_pago_service.rb)
if __FILE__ == $PROGRAM_NAME
  MercadoPagoService.create_payment_preference(
    title: 'Teste Conexão Evolution',
    quantity: 1,
    unit_price: 10.0,
    payer_email: 'comprador@email.com'
  )
end
