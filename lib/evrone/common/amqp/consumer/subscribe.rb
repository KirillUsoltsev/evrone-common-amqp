module Evrone
  module Common
    module AMQP
      module Consumer::Subscribe

        def subscribe
          session.with_channel do
            x = declare_exchange
            q = declare_queue

            bind_options = { routing_key: routing_key, headers: headers }
            q.bind(x, bind_options)

            subscription_loop

            session.close if shutdown?
          end
        end

        private

          def subscription_loop(q, &block)
            loop do
              break if shutdown?

              delivery_info, properties, payload = q.pop(ack: true)
              if payload
                run_instance delivery_info, properties, payload
                session.channel.ack delivery_info.delivery_tag, false
              else
                sleep config.pool_timeout
              end

            end
          end

          def run_instance(delivery_tag, properties, payload)
            body = try_build_from_model(message) ||
                   Common::AMQP::Message.deserialize(message, properties)

            new.perform body, properties
          end

          def try_build_from_model(message)
            if model
              model.from_json message
            end
          end

          def shutdown?
            Evrone::Common::AMQP::Session.shutdown?
          end

      end
    end
  end
end
