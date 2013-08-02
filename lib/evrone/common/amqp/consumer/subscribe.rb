module Evrone
  module Common
    module AMQP
      module Consumer::Subscribe

        def subscribe
          session.open

          session.with_channel do
            x = declare_exchange
            q = declare_queue

            bind_options = {}
            bind_options[:routing_key] = routing_key if routing_key
            bind_options[:headers]     = headers     if headers

            session.info "#{to_s} subscribing to #{q.name}:#{x.name} using #{bind_options.inspect}"
            q.bind(x, bind_options)
            session.info "#{to_s} successfuly subscribed to #{q.name}:#{x.name}"

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
                session.debug "#{to_s} receive ##{delivery_info.delivery_tag} #{payload.inspect}"
                result = run_instance delivery_info, properties, payload
                session.channel.ack delivery_info.delivery_tag, false
                session.debug "#{to_s} commit ##{delivery_info.delivery_tag}"

                break if result == :shutdown
              else
                sleep config.pool_timeout
              end
            end
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
