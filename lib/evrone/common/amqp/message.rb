require 'json'

module Evrone
  module Common
    module AMQP
      class Message

        include Helper

        attr_reader :body, :options

        class << self
          attr_reader :exchange_name, :exchange_options

          def exchange(*name)
            options = name.last.is_a?(Hash) ? name.pop : {}
            name    = name.first
            @exchange_name    = name && name.to_s
            @exchange_options = options
          end
        end

        def initialize(body, options = nil)
          @body    = body
          @options = options || {}
        end

        def routing_key
          options[:routing_key]
        end

        def to_json
          @body.respond_to?(:to_json) ? @body.to_json : ::JSON.dump(@body)
        end

        def publish(exch_name = nil, type = nil)
          exch_name ||= self.class.exchange_name
          type  = type ||
                    options[:type] ||
                    (self.class.exchange_options || {})[:type]
          r_key = routing_key
          opts  = (self.class.exchange_options || {})
                    .merge(options)
                    .merge(type: type)
                    .merge(routing_key: r_key)

          connection.publish exch_name, to_json, opts
          self
        end
      end
    end
  end
end
