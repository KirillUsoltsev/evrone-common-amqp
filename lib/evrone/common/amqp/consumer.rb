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

        include Common::AMQP::Consumer::Ack
        include Common::AMQP::Logger

        attr_accessor :delivery_info
        attr_accessor :properties
        attr_accessor :channel

        @@classes = []

        def self.included(base)
          base.extend ClassMethods
          @@classes << base.to_s
        end

        def self.classes
          @@classes
        end

        module ClassMethods

          include Common::AMQP::Consumer::Configuration
          include Common::AMQP::Consumer::Publish
          include Common::AMQP::Consumer::Subscribe
          include Common::AMQP::Logger
          include Common::AMQP::Callbacks

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
