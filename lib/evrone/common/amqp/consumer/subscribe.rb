module Evrone
  module Common
    module AMQP
      module Consumer::Subscribe

        def subscribe
          session.open

          session.with_channel do
            x = declare_exchange
            q = declare_queue

            session.info "#{consumer_name} subscribing to #{q.name}:#{x.name} using #{bind_options.inspect}"
            q.bind(x, bind_options)
            session.info "#{consumer_name} successfuly subscribed to #{q.name}:#{x.name}"

            queue_subscription_loop q

            session.info "#{to_s} shutdown"
          end
        end

        private

          def queue_subscription_loop(q)
            loop do
              break if shutdown?

              delivery_info, properties, payload = q.pop(ack: true)

              if payload
                result = nil

                log_received_message delivery_info, payload do
                  result = run_instance delivery_info, properties, payload
                  session.channel.ack delivery_info.delivery_tag, false
                end

                break if result == :shutdown
              else
                sleep config.pool_timeout
              end
            end
          end

          def log_received_message(delivery_info, payload)
            session.debug "#{consumer_name} receive ##{delivery_info.delivery_tag} #{payload.inspect}"
            yield
            session.debug "#{consumer_name} commit ##{delivery_info.delivery_tag}"
          end

          def run_instance(delivery_tag, properties, payload)
            body = try_build_from_model(payload) ||
                   Common::AMQP::Message.deserialize(payload, properties)

            new.perform body, properties
          end

          def try_build_from_model(message)
            if model
              model.from_json message
            end
          end

      end
    end
  end
end
