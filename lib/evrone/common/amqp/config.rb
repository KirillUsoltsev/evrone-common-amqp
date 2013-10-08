require 'logger'
require 'evrone/common/rack/builder'

module Evrone
  module Common
    module AMQP
      class Config

        attr_accessor :url, :default_exchange_options, :default_queue_options,
          :default_publish_options, :default_exchange_type, :logger, :pool_timeout,
          :heartbeat, :spawn_attempts, :content_type, :callbacks

        def initialize
          reset!
        end

        def formatter
          Common::AMQP::Formatter
        end

        %w{ before after }.each do |p|
          %w{ subscribe publish recieve }.each do |m|
            define_method "#{p}_#{m}" do |&callback|
              callbacks["#{p}_#{m}".to_sym] = callback
            end
          end
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

          @content_type          = 'application/json'

          @callbacks             = {}

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
