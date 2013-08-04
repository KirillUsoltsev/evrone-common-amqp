module Evrone
  module Common
    module AMQP
      module Logger

        %w{ debug info warn }.each do |m|
          define_method m do |msg|
            if log = Common::AMQP.logger
              line = "[AMQP]"
              if consumer_id = Thread.current[:amqp_consumer_id]
                line << " [#{consumer_id}]"
              end
              line << " #{msg}"
              log.send(m, line)
            end
          end
        end

      end
    end
  end
end
