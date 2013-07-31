require 'ostruct'

module Evrone
  module Common
    module AMQP
      module Consumer

        autoload :Configuration, File.expand_path("../consumer/configuration", __FILE__)


        def self.included(base)
          base.extend Helper
          base.extend Consumer::Configuration
          base.extend ClassMethods
        end

        def perform(message)
        end

        module ClassMethods

          def consume
            connection.open.subscribe(exchange_name,
                                      queue_name,
                                      routing_key: routing_key,
                                      headers:     headers,
                                      exchange:    exchange_options,
                                      queue:       queue_options)
          end
        end
      end
    end
  end
end
