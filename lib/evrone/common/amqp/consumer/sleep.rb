module Evrone
  module Common
    module AMQP
      module Consumer::Sleep

        def sleep(interval)
          if defined?(::Celluloid)
            ::Celluloid.sleep interval
          else
            Kernel.sleep interval
          end
        end

      end
    end
  end
end
