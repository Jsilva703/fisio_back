# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.3'

gem 'bcrypt', '~> 3.1'
gem 'dotenv'
gem 'json'
gem 'jwt', '~> 2.7'
gem 'mongoid', '~> 9.0'
gem 'puma', '~> 6.0'
gem 'rack-attack'
gem 'rack-cors'
gem 'rackup'
gem 'sinatra', '~> 4.0'
gem 'redis'
gem 'sidekiq'
gem 'sidekiq-scheduler'
## Mercado Pago gem removed — payments are handled externally via provider panel

group :development do
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
  gem 'erb_lint', require: false # opcional
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'rspec'
  gem 'rack-test'
end
