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

      class Message
        alias_method :real_publish, :publish

        def publish(*args)
          exch_name, _ = extract_exch_name_and_options(*args)
          Testing.exchange_messages[exch_name] << body.object
          Testing.messages << body.object
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
