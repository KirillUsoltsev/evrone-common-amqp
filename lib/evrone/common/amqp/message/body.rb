require 'json'

module Evrone
  module Common
    module AMQP
      class Message
        class Body
          attr_reader :object

          def initialize(object)
            @object = object
          end

          def serialized
            @serialized ||= (as_string ||
                             as_json   ||
                             as_default)
          end

          def content_type
            serialized
            @content_type
          end

          private

            def as_string
              if @object.is_a?(String)
                @content_type = 'text/plain'
                @object
              end
            end

            def as_json
              if @object.respond_to?(:to_json)
                @content_type = 'application/json'
                @object.to_json
              end
            end

            def as_default
              @content_type = 'text/plain'
              @object.to_s
            end
        end
      end
    end
  end
end
