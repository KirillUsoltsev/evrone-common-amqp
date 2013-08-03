require 'celluloid'

module Evrone
  module Common
    module AMQP
      module Consumer::Subscribe

        def subscribe
          session.open

          session.with_channel do
            x = declare_exchange
            q = declare_queue

            log_subscription q, x do
              q.bind(x, bind_options)
            end

            subscription_loop q

            session.warn "#{to_s} shutdown"
          end
        end

        private

          def subscription_loop(q)
            loop do
              break if shutdown?

              delivery_info, properties, payload = q.pop(ack: ack)

              if payload
                result = nil

                log_received_message delivery_info, payload do
                  result = run_instance delivery_info, properties, payload
                end

                break if result == :shutdown
              else
                sleep config.pool_timeout
              end
            end
          end

          def log_subscription(q, x)
            session.warn "#{to_s} subscribing to #{q.name}:#{x.name} using #{bind_options.inspect}"
            yield
            session.warn "#{to_s} successfuly subscribed to #{q.name}:#{x.name}"
          end

          def log_received_message(delivery_info, payload)
            session.info "#{to_s} receive ##{delivery_info.delivery_tag} #{payload.inspect}"
            yield
            session.info "#{to_s} done ##{delivery_info.delivery_tag}"
          end

          def run_instance(delivery_info, properties, payload)
            body = try_build_from_model(payload) ||
                   Common::AMQP::Message.deserialize(payload, properties)

            new.tap do |inst|
              inst.properties    = properties
              inst.delivery_info = delivery_info
            end.perform body
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
