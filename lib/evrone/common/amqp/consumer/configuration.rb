require 'ostruct'
require 'thread'

module Evrone
  module Common
    module AMQP
      module Consumer::Configuration

        @@consumer_configuration_lock = Mutex.new

        def consumer_configuration
          @consumer_configuration || reset_consumer_configuration!
        end

        def reset_consumer_configuration!
          @@consumer_configuration_lock.synchronize do
            @consumer_configuration =
              OpenStruct.new(exchange:      OpenStruct.new(options: {}),
                             queue:         OpenStruct.new(options: {}),
                             consumer_name: make_consumer_name,
                             ack:           false)
          end
        end

        %w{ exchange queue }.each do |m|
          define_method m do |*name|
            options = name.last.is_a?(Hash) ? name.pop : {}
            consumer_configuration.__send__(m).name    = name.first
            consumer_configuration.__send__(m).options = options
          end

          define_method "#{m}_name" do
            consumer_configuration.__send__(m).name || consumer_name
          end

          define_method "#{m}_options" do
            consumer_configuration.__send__(m).options
          end
        end

        def routing_key(name = nil)
          consumer_configuration.routing_key = name if name
          consumer_configuration.routing_key
        end

        def headers(values = nil)
          consumer_configuration.headers = values unless values == nil
          consumer_configuration.headers
        end

        def model(value = nil)
          consumer_configuration.model = value unless value == nil
          consumer_configuration.model
        end

        def ack(value = nil)
          consumer_configuration.ack = value unless value == nil
          consumer_configuration.ack
        end

        def consumer_name
          consumer_configuration.consumer_name
        end

        def bind_options
          consumer_configuration.bind_options ||
            @@consumer_configuration_lock.synchronize do
              opts = {}
              opts[:routing_key] = routing_key if routing_key
              opts[:headers]     = headers     if headers
              consumer_configuration.bind_options = opts
            end
        end

        private

          def make_consumer_name
            to_s.scan(/[A-Z][a-z]*/).join("_")
                .downcase
                .gsub(/_/, '.')
                .gsub(/\.consumer$/, '')
          end

      end
    end
  end
end
