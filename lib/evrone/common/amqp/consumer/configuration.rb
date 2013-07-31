require 'ostruct'

module Evrone
  module Common
    module AMQP
      module Consumer::Configuration

        def configuration
          @configuration ||= OpenStruct.new exchange: OpenStruct.new, queue: OpenStruct.new
        end

        def exchange(*name)
          options = name.last.is_a?(Hash) ? name.pop : {}
          configuration.exchange.name    = name.first
          configuration.exchange.options = options
        end

        def queue(*name)
          options = name.last.is_a?(Hash) ? name.pop : {}
          configuration.queue.name = name.first
          configuration.queue.options = options
        end

        def routing_key(name = nil)
          configuration.routing_key = name if name
          configuration.routing_key
        end

        def headers(values = nil)
          configuration.headers = values if values
          configuration.headers
        end

        def exchange_name
          if configuration.exchange.name
            configuration.exchange.name
          else
            type = exchange_options[:type] || session.config.default_exchange_type
            "amq.#{type}"
          end
        end

        def exchange_options
          configuration.exchange.options || {}
        end

        def queue_name
          configuration.queue.name
        end

        def queue_options
          configuration.queue.options || {}
        end
      end
    end
  end
end
