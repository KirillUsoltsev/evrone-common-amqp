module Evrone
  module Common
    module AMQP
      module Consumer::Ack

        def ack!(multiple = false)
          self.class.session.channel.ack delivery_info.delivery_tag, multiple
          debug "commit ##{delivery_info.consumer_tag.to_i}"
        end

        def nack!(multiple = false, requeue = false)
          self.class.session.channel.ack delivery_info.delivery_tag, multiple, requeue
          debug "reject ##{delivery_info.delivery_tag.to_i}"
        end

      end
    end
  end
end
