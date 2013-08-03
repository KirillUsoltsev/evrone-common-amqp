module Evrone
  module Common
    module AMQP
      module Consumer::Ack

        def ack!(multiple = false)
          self.class.session.channel.ack delivery_info.delivery_tag, multiple
        end

        def nack!(multiple = false, requeue = false)
          self.class.session.channel.ack delivery_info.delivery_tag, multiple, requeue
        end

      end
    end
  end
end
