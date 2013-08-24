require 'json'

module Evrone
  module Common
    module AMQP
      class Message

        attr_reader :body, :options

        class << self
          def deserialize(message, properties)
            case properties[:content_type]
            when 'application/json'
              ::JSON.parse message
            else
              message
            end
          end
        end

        def initialize(body, consumer, options = nil)
          @body     = body
          @options  = options || {}
          @consumer = consumer
        end


        def serialize
          @serialied_body ||= ( try_serialize_using_formatter || default_serializer )
        end

        private

          def formatter
            Common::AMQP.config.formatter
          end

          def try_serialize_using_formatter
            formatter.pack(options[:content_type], @consumer, @body)
          end

          def default_serializer
            @body.to_s
          end
      end
    end
  end
end
