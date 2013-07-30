require 'logger'

module Evrone
  module Common
    module AMQP
      class Config
        attr_accessor :url, :default_exchange_options, :default_queue_options,
          :default_publish_options, :default_exchange_type, :logger, :pool_timeout

        def initialize
          reset!
        end

        def reset!
          @url                   = ENV['AMQP_URL']
          @logger                = ::Logger.new(STDOUT)
          @default_exchange_type = :topic
          @pool_timeout          = 0.1

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
