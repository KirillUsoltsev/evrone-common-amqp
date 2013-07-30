module Evrone
  module Common
    module AMQP
      module Helper

        def config
          Common::AMQP.config
        end

        def logger
          config.logger
        end

        def connection
          Common::AMQP.connection
        end

      end
    end
  end
end
