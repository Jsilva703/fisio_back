require 'mongoid'
require './config/mongoid.yml'

Mongoid.load!('config/mongoid.yml', :development)

class Patient
  include Mongoid::Document
  field :name, type: String
  field :cpf, type: String
  field :company_id, type: String
end

# Busca todos os pacientes com CPF parecido
patients = Patient.where(cpf: /123/).to_a
puts "Total pacientes com '123' no CPF: #{patients.count}"
patients.each do |p|
  puts "ID: #{p.id} | Nome: #{p.name} | CPF: '#{p.cpf}' | Company: #{p.company_id}"
end

# Busca exata
exact = Patient.where(cpf: "12345678900").to_a
puts "\nBusca exata '12345678900': #{exact.count}"

# Busca com formatação
formatted = Patient.where(cpf: "123.456.789-00").to_a
puts "Busca formatada '123.456.789-00': #{formatted.count}"
