module Evrone
  module Common
    module AMQP
      module Helper

        module Config
          def config
            Common::AMQP.config
          end
        end

        module Logger
          def logger
            Common::AMQP.logger
          end
        end

        module Session
          def session
            Common::AMQP.session
          end
        end

        module Shutdown
          def shutdown
            Common::AMQP::Session.shutdown
          end
        end

      end
    end
  end
end
