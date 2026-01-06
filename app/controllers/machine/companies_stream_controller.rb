# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'redis'

module Machine
  class CompaniesStreamController < Sinatra::Base
    configure do
      set :server, :puma
    end

    get '/stream' do
      content_type 'text/event-stream'
      stream(:keep_open) do |out|
        begin
          require 'redis'
          redis_url = ENV['REDIS_URL'] || 'redis://127.0.0.1:6379'
          # Subscriber runs in its own thread so the request thread can handle keepalive and cleanup
          subscriber = Redis.new(url: redis_url)

          sub_thread = Thread.new do
            begin
              subscriber.subscribe('companies:new', 'companies:requested') do |on|
                on.message do |channel, msg|
                  begin
                    type = channel == 'companies:requested' ? 'requested' : 'created'
                    parsed = begin
                      JSON.parse(msg)
                    rescue StandardError
                      msg
                    end
                    payload = { type: type, payload: parsed }
                    out << "data: #{payload.to_json}\n\n"
                  rescue IOError
                    # client disconnected
                    subscriber.unsubscribe
                  rescue StandardError => e
                    begin
                      out << "event: error\ndata: #{ { error: e.message }.to_json }\n\n"
                    rescue StandardError
                    end
                  end
                end
              end
            rescue StandardError => e
              begin
                out << "event: error\ndata: #{ { error: e.message }.to_json }\n\n"
              rescue StandardError
              end
            end
          end

          # heartbeat to keep proxies from timing out
          heartbeat = Thread.new do
            loop do
              sleep 15
              begin
                out << ": ping\n\n"
              rescue StandardError
                break
              end
            end
          end

          out.callback do
            begin
              subscriber.unsubscribe
            rescue StandardError
            end
            sub_thread.kill if sub_thread.alive?
            heartbeat.kill if heartbeat.alive?
          end

          out.errback do
            begin
              subscriber.unsubscribe
            rescue StandardError
            end
            sub_thread.kill if sub_thread.alive?
            heartbeat.kill if heartbeat.alive?
          end
        rescue StandardError => e
          out << "event: error\ndata: #{ { error: e.message }.to_json }\n\n"
          out.close
        end
      end
    end
  end
end
