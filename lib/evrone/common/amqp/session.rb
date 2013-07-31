require 'bunny'

module Evrone
  module Common
    module AMQP
      class Session

        CHANNEL_KEY = :evrone_amqp_channel

        attr_reader :conn

        include Helper

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
            logger.info "[amqp] close connection"
          end
          @conn = nil
          self
        end

        def open
          @conn ||= begin
            self.class.resume

            @conn = ::Bunny.new config.url,
              heartbeat: config.heartbeat,
              logger:    config.logger

            info "connecting to #{conn_info}"
            @conn.start
            info "connected successfuly (#{server_name})"
            @conn
          end
          self
        end

        def open?
          conn && conn.open?
        end

        def publish(exch_name, body, options = {})
          assert_connection_is_open


          x_options   = options.delete(:exchange) || {}
          x           = declare_exchange exch_name, x_options

          debug "publising message #{body.inspect} to '#{x.name}' with #{options.inspect}"
          x.publish body, options
          debug "message successfuly published"
          true
        end

        def subscribe(exch_name, queue_name, options = {}, &block)
          with_channel do
            info "subscribing to #{exch_name}"

            bind_options = extract_bind_options! options
            x            = declare_exchange exch_name,  options[:exchange]
            q            = declare_queue    queue_name, options[:queue]

            q.bind(x, bind_options)
            info "subscribed to '#{q.name}' and bind to '#{x.name}' with #{bind_options.inspect}"

            subscribtion_loop x, q, &block

            close if shutdown?
          end
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

        private

          def subscribtion_loop(x, q, &block)
            loop do
              break if shutdown?

              delivery_info, properties, payload = q.pop(ack: true)
              if payload
                log_received_message delivery_info, payload do
                  yield delivery_info, properties, payload
                  channel.ack delivery_info.delivery_tag, false
                end
              else
                sleep config.pool_timeout
              end
            end
          end

          def shutdown?
            self.class.shutdown?
          end

          def log_received_message(delivery_info, payload)
            info "receive ##{delivery_info.delivery_tag} #{payload.inspect}"
            status = yield
            info "commit ##{delivery_info.delivery_tag}"
            status
          end

          def get_exchange_type_and_options(options)
            options = config.default_exchange_options.merge(options || {})
            type = options.delete(:type) || config.default_exchange_type
            [type, options]
          end

          def get_queue_name_and_options(name, options)
            name  ||= AMQ::Protocol::EMPTY_STRING
            [name, config.default_queue_options.merge(options || {})]
          end

          def extract_bind_options!(options)
            { routing_key: options.delete(:routing_key) }
          end

          def assert_connection_is_open
            raise(ConnectionNotOpened, "call Evrone::Common::AMQP.open first") unless conn && conn.open?
          end

          def debug(msg)
            logger.debug(open? ? "[amqp##{channel.id}] #{msg}" : "[amqp] #{msg}")
          end

          def info(msg)
            logger.info(open? ? "[amqp##{channel.id}] #{msg}" : "[amqp] #{msg}")
          end

          class ConnectionNotOpened < ::Exception ; end
      end
    end
  end
end
