require 'bunny'
require 'thread'

module Evrone
  module Common
    module AMQP
      class Session

        CHANNEL_KEY = :evrone_amqp_channel

        @@session_lock = Mutex.new

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
            begin
              @@session_lock.synchronize do
                conn.close
              end
            rescue Bunny::ChannelError => e
              warn e
            end
            warn "close connection"
          end
        end

        def open
          return self if conn && conn.open?

          @@session_lock.synchronize do
            self.class.resume

            @conn ||= Bunny.new config.url, heartbeat: :server

            unless conn.open?
              warn "connecting to #{conn_info}"
              conn.start
              warn "wait connection to #{conn_info}"
              while conn.connecting?
                Common::AMQP.sleep 0.01
              end
              warn "connected successfuly (#{server_name})"
            end
          end

          self
        end

        def open?
          conn && conn.open? && conn.status == :open
        end

        def declare_exchange(name, options = nil)
          assert_connection_is_open

          options  ||= {}
          name     ||= config.default_exchange_name
          ch         = options.delete(:channel) || channel
          type, opts = get_exchange_type_and_options options
          ch.exchange name, opts.merge(type: type)
        end

        def declare_queue(name, options = nil)
          assert_connection_is_open

          options ||= {}
          ch = options.delete(:channel) || channel
          name, opts = get_queue_name_and_options(name, options)
          ch.queue name, opts
        end

        def channel
          assert_connection_is_open

          Thread.current[CHANNEL_KEY] || conn.default_channel
        end

        def with_channel
          assert_connection_is_open

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

          def assert_connection_is_open
            open? || raise(ConnectionDoesNotExist.new "you need to run #{to_s}#open")
          end

          class ConnectionDoesNotExist < ::Exception ; end

      end
    end
  end
end
