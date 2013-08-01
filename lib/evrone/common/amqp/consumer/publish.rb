module Evrone
  module Common
    module AMQP
      module Consumer::Publish

        def publish(message, options = nil)
          session.open

          m  = Common::AMQP::Message.new(message, options)
          x  = declare_exchange

          options ||= {}
          options[:routing_key] ||= routing_key
          options[:headers]     ||= headers

          session.debug "#{to_s} publishing #{message.inspect} to #{x.name}"
          x.publish m.serialize, m.options
          session.debug "#{to_s} successfuly published"
          self
        end

      end
    end
  end
end
