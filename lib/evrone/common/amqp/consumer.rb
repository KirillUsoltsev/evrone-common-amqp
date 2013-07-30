require 'ostruct'

module Evrone
  module Common
    module AMQP
      module Consumer

        def self.included(base)
          base.__send__ :extend, ClassMethods
        end

        def perform(message)
        end

        module ClassMethods
          extend Helper

          def configuration
            @configuration ||= OpenStruct.new exchange: OpenStruct.new, queue: OpenStruct.new
          end

          def exchange(name, options = {})
            configuration.exchange.name = name
            configuration.exchange.options = options
          end

          def queue(name, options = {})
            configuration.queue.name = name
            configuration.queue.options = options
          end

          def consume
            connection.open
            
          end
        end
      end
    end
  end
end
