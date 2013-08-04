module Evrone
  module Common
    module AMQP
      module Logger

        %w{ debug info warn }.each do |m|
          define_method m do |msg|
            if log = Common::AMQP.logger
              log.send(m, "[AMQP] #{msg}")
            end
          end
        end

      end
    end
  end
end
