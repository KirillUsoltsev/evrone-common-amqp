require 'bunny'

module Evrone
  module Common
    module AMQP
      class Connection

        attr_reader :conn, :channel

        include Helper

        def close
          if conn && conn.open?
            close_channel
            conn.close
            logger.info "[amqp] close connection"
          end
          @conn = nil
        end

        def open
          @conn ||= begin
            @conn = ::Bunny.new config.url
            logger.info "[amqp] connecting to #{conn_info}"
            @conn.start
            logger.info "[amqp] connected successfuly"
            open_channel
            @conn
          end
          self
        end

        def publish(exch_name, body, options = {})
          x = declare_exchange exch_name, options
          x.publish body
          true
        end

        def subscribe(exch_name, queue_name, options = {}, &block)
          logger.info "[amqp] subscribing to #{exch_name}"

          bind_options = {
            routing_key: options[:routing_key]
          }

          x = declare_exchange exch_name,  options[:exchange]
          q = declare_exchange queue_name, options[:queue]
          q.bind(x, bind_options)
          logger.info "[amqp] bind queue '#{q.name}' to '#{x.name}'"

          begin
            loop do
              delivery_info, _, payload = q.pop(ack: true)
              if payload
                logger.info "[amqp] receive ##{delivery_info.delivery_tag} #{payload.inspect}"
                yield payload, delivery_info
                channel.ack delivery_info.delivery_tag, false
                logger.info "[amqp] commit ##{delivery_info.delivery_tag}"
              else
                sleep config.pool_timeout
              end
            end
          end
        end

        def conn_info
          "#{@conn.user}:#{@conn.host}:#{@conn.port}/#{@conn.vhost}" if @conn
        end

        private

          def open_channel
            logger.info '[amqp] openning channel'
            @channel = conn.create_channel
            logger.info "[amqp] channel ##{channel.id} opened successfuly"
            channel.prefetch(1)
          end

          def close_channel
            if channel && channel.open?
              logger.info "[amqp] close channel ##{channel.id}"
              channel.close
            end
            @channel = nil
          end

          def declare_exchange(name, options = {})
            assert_connection_opened

            type = options.delete(:type) || config.default_exchange_type
            options = config.default_exchange_options.merge(options)
            ::Bunny::Exchange.new(@channel, type, name, options)
          end

          def declare_queue(name, options = {})
            assert_connection_opened

            options = config.default_queue_options.merge(options || {})

            if options[:auto_delete] && options[:exclusive]
              options.merge!(durable:     false,
                             auto_delete: true)
            end

            name ||= AMQ::Protocol::EMPTY_STRING
            channel.queue name, options
          end

          def assert_connection_opened
            raise(ConnectionNotOpened, "call Evrone::Common::AMQP.open first") unless conn && conn.open?
          end

          class ConnectionNotOpened < ::Exception ; end
      end
    end
  end
end
