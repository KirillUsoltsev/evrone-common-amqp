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

        def initialize(body, options = nil)
          @body            = body
          @options         = options || {}
        end

        def content_type
          options[:content_type]
        end

        def serialize
          @serialied_body ||= ( try_serialize_strings ||
                                try_serialize_using_to_json   ||
                                default_serializer )
        end

        private

          def try_serialize_strings
            if @body.is_a?(String)
              options[:content_type] ||= 'text/plain'
              @body
            end
          end

          def try_serialize_using_to_json
            if @object.respond_to?(:to_json)
              options[:content_type] ||= 'application/json'
              @body.to_json
            end
          end

          def default_serializer
            options[:content_type] ||= 'text/plain'
            @body.to_s
          end
      end
    end
  end
end
