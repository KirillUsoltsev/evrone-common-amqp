require 'logger'

module Evrone
  module Common
    module AMQP
      class Config
        attr_accessor :url, :default_exchange_options, :default_queue_options,
          :default_publish_options, :default_exchange_type, :logger

        def initialize
          reset!
        end

        def reset!
          @url    = ENV['AMQP_URL']
          @logger = ::Logger.new(STDOUT)


          @default_exchange_options = {
            durable: true
          }

          @default_queue_options = {
            durable: true,
            autodelete: false,
            exclusive: false
          }

          @default_publish_options = {
            durable: false
          }

          @default_exchange_type = :topic
        end
      end
    end
  end
end
