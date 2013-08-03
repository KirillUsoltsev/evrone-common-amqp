module Evrone
  module Common
    module AMQP
      module Consumer::Ack

        def ack!(multiple = false)
          self.class.session.channel.ack delivery_info.delivery_tag, multiple
          session.info "commit ##{delivery_info.delivery_tag}"
        end

        def nack!(multiple = false, requeue = false)
          self.class.session.channel.ack delivery_info.delivery_tag, multiple, requeue
          session.info "reject ##{delivery_info.delivery_tag}"
        end

      end
    end
  end
end
