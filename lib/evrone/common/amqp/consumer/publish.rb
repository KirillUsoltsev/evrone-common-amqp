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

          m  = Common::AMQP::Message.new(message, self, options)
          x  = declare_exchange

          with_middleware :publishing, message: m, exchange: x do |opts|
            x.publish opts[:message].serialize, opts[:message].options
          end

          debug "published #{message.inspect} to #{x.name}"
          self
        end

      end
    end
  end
end
