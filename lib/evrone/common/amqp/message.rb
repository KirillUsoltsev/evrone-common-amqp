module Evrone
  module Common
    module AMQP
      class Message

        autoload :Body, File.expand_path("../message/body", __FILE__)

        include Helper

        attr_reader :body, :options

        def initialize(body, options = nil)
          @body              = Body.new body
          @options           = options || {}
        end

        def routing_key
          options[:routing_key]
        end

        def content_type
          @options[:content_type] || @body.content_type
        end

        def serialized
          body.serialized
        end

        def publish(*args)
          exch_name, exch_options = extract_exch_name_and_options(*args)

          options.merge! content_type: content_type

          session.publish exch_name,
                          serialized,
                          options.merge(exchange: exch_options)
          self
        end

        private

          def extract_exch_name_and_options(*args)
            exch_options = args.last.is_a?(Hash) ? args.pop : {}

            exch_name = args.first
            [exch_name, exch_options]
          end
      end
    end
  end
end
