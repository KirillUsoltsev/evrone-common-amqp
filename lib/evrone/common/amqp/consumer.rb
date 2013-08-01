require 'ostruct'

module Evrone
  module Common
    module AMQP
      module Consumer

        autoload :Configuration, File.expand_path("../consumer/configuration", __FILE__)

        def self.included(base)
          base.extend Helper::Session
          base.extend Helper::Logger
          base.extend Helper::Shutdown
          base.extend Consumer::Configuration
          base.extend ClassMethods
        end

        def perform(message, properties)
        end

        module ClassMethods

          def publish(message, options = {})
            options = {
              routing_key: routing_key,
              headers: headers
            }.merge(options)
            Message.new(message, options).publish(exchange_name, exchange_options)
          end

          def consume
            logger.info  "[amqp] start consumer #{to_s}"
            @cached_object = new

            session.subscribe(exchange_name, queue_name,
                              routing_key: routing_key,
                              headers:     headers,
                              exchange:    exchange_options,
                              queue:       queue_options,
                              &method(:subscription_loop))
            logger.info "[amqp] stop consumer #{to_s}"
          end

          def subscription_loop(delivery_info, properties, payload)
            message = Message::Body.deserialize payload, properties, model: model
            create_object.perform message, properties
          end

          def create_object
            new
          end

          def consumer_name
            @consumer_tag ||= to_s.scan(/[A-Z][a-z]*/).join("_").downcase.gsub(/_/, '.')
          end
        end
      end
    end
  end
end
