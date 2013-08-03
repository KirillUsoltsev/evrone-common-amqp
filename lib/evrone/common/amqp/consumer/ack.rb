module Evrone
  module Common
    module AMQP
      module Consumer::Ack

        def ack!(multiple = false)
          self.class.session.channel.ack delivery_info.delivery_tag, multiple
          Common::AMQP.session.info "#{self.class.to_s} commit ##{delivery_info.delivery_tag}"
        end

        def nack!(multiple = false, requeue = false)
          self.class.session.channel.ack delivery_info.delivery_tag, multiple, requeue
          Common::AMQP.session.info "#{self.class.to_s} reject ##{delivery_info.delivery_tag}"
        end

      end
    end
  end
end
