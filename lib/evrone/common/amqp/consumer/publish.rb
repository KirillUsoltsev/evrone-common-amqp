module Evrone
  module Common
    module AMQP
      module Consumer::Publish

        def publish(message, options = nil)
          m  = Common::AMQP::Message.new(message, options)
          x  = declare_exchange

          options ||= {}
          options[:routing_key] ||= routing_key
          options[:headers]     ||= headers

          x.publish m.serialize, m.options
        end

      end
    end
  end
end
