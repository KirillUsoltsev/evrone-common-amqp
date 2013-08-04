require 'logger'
require 'evrone/common/rack/builder'

module Evrone
  module Common
    module AMQP
      class Config

        attr_accessor :url, :default_exchange_options, :default_queue_options,
          :default_publish_options, :default_exchange_type, :logger, :pool_timeout,
          :heartbeat, :spawn_attempts

        attr_reader  :publishing_builder, :recieving_builder, :subscribing_builder

        def initialize
          reset!
        end

        def publishing(&block)
          @publishing_builder = Common::Rack::Builder.new(&block)
        end

        def recieving(&block)
          @recieving_builder = Common::Rack::Builder.new(&block)
        end

        def subscribing(&block)
          @subscribing_builder = Common::Rack::Builder.new(&block)
        end

        def default_exchange_name
          "amq.#{default_exchange_type}"
        end

        def reset!
          @url                   = nil
          @logger                = ::Logger.new(STDOUT)
          @default_exchange_type = :topic
          @pool_timeout          = 0.1
          @heartbeat             = 10

          @publishing_builder    = nil
          @recieving_builder     = nil
          @subscribing_builder   = nil

          @spawn_attempts        = 5

          @default_exchange_options = {
            durable:     true,
            auto_delete: false
          }

          @default_queue_options = {
            durable:     true,
            autodelete:  false,
            exclusive:   false
          }

          @default_publish_options = {
            durable:     false
          }

        end

      end
    end
  end
end
