require 'ostruct'

module Evrone
  module Common
    module AMQP
      module Consumer::Configuration

        def consumer_configuration
          @consumer_configuration ||= reset_consumer_configuration!
        end

        def reset_consumer_configuration!
          @consumer_configuration = OpenStruct.new(exchange: OpenStruct.new(options: {}),
                                                   queue:    OpenStruct.new(options: {}))
        end

        def exchange(*name)
          options = name.last.is_a?(Hash) ? name.pop : {}
          consumer_configuration.exchange.name    = name.first
          consumer_configuration.exchange.options = options
        end

        def queue(*name)
          options = name.last.is_a?(Hash) ? name.pop : {}
          consumer_configuration.queue.name = name.first
          consumer_configuration.queue.options = options
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

        def exchange_name
          consumer_configuration.exchange.name || consumer_name
        end

        def exchange_options
          consumer_configuration.exchange.options
        end

        def queue_name
          consumer_configuration.queue.name || consumer_name
        end

        def queue_options
          consumer_configuration.queue.options
        end

        def consumer_name
          @consumer_name ||= to_s.scan(/[A-Z][a-z]*/).join("_").downcase.gsub(/_/, '.')
        end

      end
    end
  end
end
