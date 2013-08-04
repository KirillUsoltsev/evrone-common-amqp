module Evrone
  module Common
    module AMQP
      module WithMiddleware
        def with_middleware(name, env, &block)
          builder = Common::AMQP.config.public_send("#{name}_builder")
          if builder
            builder.to_app(block).call env
          else
            yield env
          end
        end
      end
    end
  end
end
