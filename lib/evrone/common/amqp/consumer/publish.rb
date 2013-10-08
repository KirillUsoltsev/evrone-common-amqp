module Evrone
  module Common
    module AMQP
      module Consumer::Publish

        def publish(message, options = nil)
          session.open

          options ||= {}
          options[:routing_key]  = routing_key if routing_key && !options.key?(:routing_key)
          options[:headers]      = headers     if headers && !options.key?(:headers)
          options[:content_type] ||= content_type || config.content_type

          x = declare_exchange

          run_callbacks(:publish, message: message, exchange: x, name: consumer_name) do
            m = serialize_message message, options[:content_type]
            x.publish m, options
          end

          debug "published #{message.inspect} to #{x.name}"
          self
        end

        def serialize_message(message, content_type)
          Common::AMQP::Formatter.pack(content_type, message)
        end

      end
    end
  end
end
