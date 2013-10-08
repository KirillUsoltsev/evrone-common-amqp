module Evrone
  module Common
    module AMQP
      module Callbacks

        def run_callbacks(name, *args)
          before = "before_#{name}".to_sym
          after  = "after_#{name}".to_sym
          if f = Common::AMQP.config.callbacks[before]
            f.call(*args)
          end

          rs = yield if block_given?

          if f = Common::AMQP.config.callbacks[after]
            f.call(*args)
          end

          rs
        end

      end
    end
  end
end
