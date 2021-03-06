require 'ostruct'
require 'thread'

module Evrone
  module Common
    module AMQP
      module Consumer::Configuration

        @@consumer_configuration_lock = Mutex.new

        def consumer_configuration
          @consumer_configuration || reset_consumer_configuration!
        end

        def reset_consumer_configuration!
          @@consumer_configuration_lock.synchronize do
            @consumer_configuration =
              OpenStruct.new(exchange:      OpenStruct.new(options: {}),
                             queue:         OpenStruct.new(options: {}),
                             consumer_name: make_consumer_name,
                             ack:           false,
                             content_type:  nil)
          end
        end

        %w{ exchange queue }.each do |m|
          define_method m do |*name, &b|
            options = name.last.is_a?(Hash) ? name.pop : {}
            val = b || name.first
            consumer_configuration.__send__(m).name    = val
            consumer_configuration.__send__(m).options = options
          end

          define_method "#{m}_name" do
            value_maybe_proc(consumer_configuration.__send__(m).name || consumer_name)
          end

          define_method "#{m}_options" do
            value_maybe_proc(consumer_configuration.__send__(m).options)
          end
        end

        def routing_key(name = nil, &block)
          val = block || name
          if val
            consumer_configuration.routing_key = val
          else
            value_maybe_proc consumer_configuration.routing_key
          end
        end

        def headers(values = nil, &block)
          val = block || values
          if val
            consumer_configuration.headers = val
          else
            value_maybe_proc consumer_configuration.headers
          end
        end

        def model(value = nil)
          consumer_configuration.model = value unless value == nil
          consumer_configuration.model
        end

        def content_type(value = nil)
          consumer_configuration.content_type = value if value
          consumer_configuration.content_type
        end

        def ack(value = nil)
          consumer_configuration.ack = value unless value == nil
          consumer_configuration.ack
        end

        def consumer_name
          consumer_configuration.consumer_name
        end

        def consumer_id
          if cid = Thread.current[:evrone_amqp_consumer_id]
            "#{consumer_name}.#{cid}"
          else
            consumer_name
          end
        end

        def bind_options
          consumer_configuration.bind_options ||
            @@consumer_configuration_lock.synchronize do
              opts = {}
              opts[:routing_key] = routing_key if routing_key
              opts[:headers]     = headers     if headers
              consumer_configuration.bind_options = opts
            end
        end

        private

          def value_maybe_proc(val)
            case val
            when Proc
              val.call
            else
              val
            end
          end

          def make_consumer_name
            to_s.split("::")
                .last
                .scan(/[A-Z][a-z]*/).join("_")
                .downcase
          end

      end
    end
  end
end
