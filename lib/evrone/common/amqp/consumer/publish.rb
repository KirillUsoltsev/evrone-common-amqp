module Evrone
  module Common
    module AMQP
      module Consumer::Publish

        def publish(message, options = nil)
          session.open

          options ||= {}
          options[:routing_key] = routing_key if routing_key && !options.key?(:routing_key)
          options[:headers]     = headers     if headers && !options.key?(:headers)

          m  = Common::AMQP::Message.new(message, options)
          x  = declare_exchange

          x.publish m.serialize, m.options
          session.debug "published #{message.inspect} to #{x.name}"
          self
        end

      end
    end
  end
end
