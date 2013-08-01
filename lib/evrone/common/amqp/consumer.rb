require 'ostruct'

module Evrone
  module Common
    module AMQP
      module Consumer

        autoload :Configuration, File.expand_path("../consumer/configuration", __FILE__)
        autoload :Publish,       File.expand_path("../consumer/publish",       __FILE__)
        autoload :Subscribe,     File.expand_path("../consumer/subscribe",     __FILE__)

        def self.included(base)

          base.extend Helper::Session
          base.extend Helper::Logger

          base.extend Consumer::Configuration
          base.extend Consumer::Publish
          base.extend Consumer::Subscribe

          base.extend ClassMethods
        end

        module ClassMethods

          def consumer_name
            @consumer_name ||= to_s.scan(/[A-Z][a-z]*/).join("_").downcase.gsub(/_/, '.')
          end

          private

            def declare_exchange
              session.declare_exchange(exchange_name, exchange_options)
            end

            def declare_queue
              session.declare_queue(queue_name, queue_options)
            end

        end
      end
    end
  end
end
