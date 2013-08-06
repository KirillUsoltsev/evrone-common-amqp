module Evrone
  module Common
    module AMQP
      module Consumer::Publish

        def publish(message, options = nil)
          session.open

          options ||= {}
          options[:routing_key] = routing_key if routing_key && !options.key?(:routing_key)
          options[:headers]     = headers     if headers && !options.key?(:headers)

          session.with_channel true do
            m  = Common::AMQP::Message.new(message, options)
            x  = declare_exchange

            with_middleware :publishing, message: m, exchange: x do |opts|
              x.publish opts[:message].serialize, opts[:message].options
            end

            debug "published #{message.inspect} to #{x.name}"
          end
          self
        end

      end
    end
  end
end
