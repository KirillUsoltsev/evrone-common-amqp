require 'json'

module Evrone
  module Common
    module AMQP
      class Message

        include Helper

        attr_reader :body, :options

        def initialize(body, options = {})
          @body    = body
          @options = options
        end

        def routing_key
          options[:routing_key]
        end

        def to_json
          @body.respond_to?(:to_json) ? @body.to_json : ::JSON.dump(@body)
        end

        def publish(exch_name, type = nil, options = {})
          connection.publish exch_name, to_json, options.merge(type: type)
        end
      end
    end
  end
end
