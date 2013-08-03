require 'ostruct'

module Evrone
  module Common
    module AMQP
      module Consumer

        autoload :Configuration, File.expand_path("../consumer/configuration", __FILE__)
        autoload :Publish,       File.expand_path("../consumer/publish",       __FILE__)
        autoload :Subscribe,     File.expand_path("../consumer/subscribe",     __FILE__)
        autoload :Sleep,         File.expand_path("../consumer/sleep",         __FILE__)
        autoload :Ack,           File.expand_path("../consumer/ack",           __FILE__)

        include Consumer::Sleep
        include Consumer::Ack

        attr_accessor :delivery_info
        attr_accessor :properties
        attr_accessor :channel

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

          include Consumer::Configuration
          include Consumer::Publish
          include Consumer::Subscribe
          include Consumer::Sleep

          def shutdown?
            Common::AMQP.shutdown?
          end

          def shutdown
            Common::AMQP.shutdown
          end

          def session
            Common::AMQP.session
          end

          def config
            Common::AMQP.config
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
