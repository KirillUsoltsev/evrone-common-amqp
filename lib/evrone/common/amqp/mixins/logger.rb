module Evrone
  module Common
    module AMQP
      module Logger

        %w{ debug info warn }.each do |m|
          define_method m do |msg|
            if log = Common::AMQP.logger
              ch = Thread.current[Common::AMQP::Session::CHANNEL_KEY]
              id = ch && ch.id
              pre = "[AMQP"
              if id
                pre << " #{id}"
              end
              log.send(m, "#{pre}] #{msg}")
            end
          end
        end

      end
    end
  end
end
