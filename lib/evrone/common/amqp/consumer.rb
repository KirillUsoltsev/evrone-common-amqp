require 'ostruct'

module Evrone
  module Common
    module AMQP
      module Consumer

        autoload :Configuration, File.expand_path("../consumer/configuration", __FILE__)

        def self.included(base)
          base.extend Helper::Session
          base.extend Helper::Logger
          base.extend Consumer::Configuration
          base.extend ClassMethods
        end

        def perform(message)
        end

        module ClassMethods

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
            cached_object.perform payload
          end

          def cached_object
            @cached_options
          end
        end
      end
    end
  end
end
