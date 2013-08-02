require 'bunny'

module Evrone
  module Common
    module AMQP
      class Session

        CHANNEL_KEY = :evrone_amqp_channel

        attr_reader :conn

        class << self
          def shutdown
            @shutdown = true
          end

          def shutdown?
            @shutdown == true
          end

          def resume
            @shutdown = false
          end
        end

        def close
          if conn && conn.open?
            conn.close
            warn "close connection"
          end
        end

        def open
          self.class.resume

          @conn ||= Bunny.new config.url, heartbeat: :server

          unless conn.open?
            warn "connecting to #{conn_info}"
            conn.start
            warn "connected successfuly (#{server_name})"
          end

          self
        end

        def open?
          conn && conn.open?
        end

        def declare_exchange(name, options = nil)
          options  ||= {}
          name     ||= config.default_exchange_name
          ch         = options.delete(:channel) || channel
          type, opts = get_exchange_type_and_options options
          ch.exchange name, opts.merge(type: type)
        end

        def declare_queue(name, options = nil)
          options ||= {}
          ch = options.delete(:channel) || channel
          name, opts = get_queue_name_and_options(name, options)
          ch.queue name, opts
        end

        def channel
          Thread.current[CHANNEL_KEY] || conn.default_channel
        end

        def with_channel
          old,new = nil
          begin
            old,new = Thread.current[CHANNEL_KEY], conn.create_channel
            Thread.current[CHANNEL_KEY] = new
            yield
          ensure
            Thread.current[CHANNEL_KEY] = old
            new.close if new && new.open?
          end
        end

        def conn_info
          if conn
            "#{conn.user}:#{conn.host}:#{conn.port}/#{conn.vhost}"
          end
        end

        def server_name
          if conn
            p = conn.server_properties || {}
            "#{p["product"]}/#{p["version"]}"
          end
        end

        %w{ debug info warn }.each do |m|
          define_method m do |msg|
            Common::AMQP.logger.public_send(m,
              ((open? && channel) ? "[amqp:#{channel.id}] #{msg}" : "[amqp] #{msg}")
            )
          end
        end

        def config
          Common::AMQP.config
        end

        private

          def get_exchange_type_and_options(options)
            options = config.default_exchange_options.merge(options || {})
            type = options.delete(:type) || config.default_exchange_type
            [type, options]
          end

          def get_queue_name_and_options(name, options)
            name  ||= AMQ::Protocol::EMPTY_STRING
            [name, config.default_queue_options.merge(options || {})]
          end

      end
    end
  end
end
