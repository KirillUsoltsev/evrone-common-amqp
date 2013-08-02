require File.expand_path("../../amqp", __FILE__)

module Evrone
  module Common
    module AMQP
      module Testing

        extend self

        def messages
          @messages ||= []
        end

        def exchange_messages
          @exchange_messages ||= Hash.new { |h,k| h[k] = [] }
        end

        def clear
          messages.clear
          exchange_messages.clear
        end
      end

      module Consumer::Publish
        alias_method :real_publish, :publish

        def publish(message, options = {})
          Testing.exchange_messages[exchange_name] << message
          Testing.messages << message
          self
        end
      end

      module Consumer
        module ClassMethods
          def messages
            Testing.exchange_messages[exchange_name]
          end
        end
      end
    end
  end
end
