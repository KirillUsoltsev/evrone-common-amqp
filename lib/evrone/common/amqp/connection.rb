require 'bunny'

module Evrone
  module Common
    module AMQP
      class Connection

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
            self.class.resume
          end
          @conn = nil
          self
        end

        def open
          @conn ||= begin
            self.class.resume
            @conn = ::Bunny.new config.url
            logger.info "[amqp] connecting to #{conn_info}"
            @conn.start
            logger.info "[amqp] connected successfuly (#{server_name})"
            @conn
          end
          self
        end

        def opened?
          conn && conn.opened?
        end

        def publish(exch_name, body, options = {})
          logger.debug "[amqp] publising message #{body.inspect} to '#{exch_name}'"
          routing_key = options.delete(:routing_key)
          headers     = options.delete(:headers)
          x           = declare_exchange exch_name, options
          x.publish body, routing_key: routing_key, headers: headers
          logger.debug "[amqp] message published successfuly"
          true
        end

        def subscribe(exch_name, queue_name, options = {}, &block)
          logger.info "[amqp] subscribing to #{exch_name}"

          bind_options = extract_bind_options! options
          x            = declare_exchange exch_name,  options[:exchange]
          q            = declare_queue    queue_name, options[:queue]

          q.bind(x, bind_options)
          logger.info "[amqp] bind queue '#{q.name}' to '#{x.name}'"

          begin
            loop do
              break if shutdown?

              delivery_info, _, payload = q.pop(ack: true)
              if payload
                log_received_message delivery_info, payload do
                  yield payload, delivery_info
                  channel.ack delivery_info.delivery_tag, false
                end
              else
                sleep config.pool_timeout
              end
            end
          end

          close if shutdown?
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

        def channel
          assert_connection_open
          conn.default_channel and conn.default_channel
        end

        private

          def shutdown?
            self.class.shutdown?
          end

          def log_received_message(delivery_info, payload)
            logger.info "[amqp] receive ##{delivery_info.delivery_tag} #{payload.inspect}"
            status = yield
            logger.info "[amqp] commit ##{delivery_info.delivery_tag}"
            status
          end

          def declare_exchange(name, options = nil)
            assert_connection_open
            logger.debug "[amqp] declaring exchange #{name.inspect} #{options.inspect}"
            type, options = get_exchange_type_and_options(options || {})
            x = ::Bunny::Exchange.new(channel, type, name, options)
            logger.debug "[amqp] declated exchnage successful #{x.inspect[0..80]}"
            x
          end

          def declare_queue(name, options = nil)
            assert_connection_open

            options = get_queue_options(options || {})
            name  ||= AMQ::Protocol::EMPTY_STRING
            logger.debug "[amqp] declaring queue #{name.inspect} #{options.inspect}"
            q = channel.queue name, options
            logger.debug "[amqp] declated queue successful #{q.inspect[0..80]}"
            q
          end

          def get_exchange_type_and_options(options)
            options = config.default_exchange_options.merge(options)
            type = options.delete(:type) || config.default_exchange_type
            [type, options]
          end

          def get_queue_options(options)
            config.default_queue_options.merge(options || {})
          end

          def extract_bind_options!(options)
            { routing_key: options.delete(:routing_key) }
          end

          def assert_connection_open
            raise(ConnectionNotOpened, "call Evrone::Common::AMQP.open first") unless conn && conn.open?
          end

          class ConnectionNotOpened < ::Exception ; end
      end
    end
  end
end
