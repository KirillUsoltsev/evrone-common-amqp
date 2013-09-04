require File.expand_path("../../amqp", __FILE__)

module Evrone
  module Common
    module AMQP
      module Testing

        extend self

        @@messages = Hash.new { |h,k| h[k] = [] }
        @@messages_and_options = Hash.new { |h,k| h[k] = [] }

        def messages
          @@messages
        end

        def messages_and_options
          @@messages_and_options
        end

        def clear
          messages.clear
          messages_and_options.clear
        end
      end

      module Consumer::Publish
        alias_method :real_publish, :publish

        def publish(message, options = nil)
          options ||= {}
          Testing.messages[exchange_name] << message
          Testing.messages_and_options[exchange_name] << [message, options]
          self
        end

      end

      module Consumer
        module ClassMethods

          def messages
            Testing.messages[exchange_name]
          end

          def messages_and_options
            Testing.messages_and_options[exchange_name]
          end

        end
      end
    end
  end
end
