module Evrone
  module Common
    module AMQP
      module Consumer::Subscribe

        def subscribe
          session.open

          session.with_channel do
            x = declare_exchange
            q = declare_queue

            with_middleware(:subscribing, exchange: x, queue: q) do |_|
              debug "subscribing to #{q.name}:#{x.name} using #{bind_options.inspect}"
              q.bind(x, bind_options)
              debug "successfuly subscribed to #{q.name}:#{x.name}"

              subscription_loop q
            end

            debug "shutdown"
          end
        end

        private

          def subscription_loop(q)
            loop do
              break if shutdown?

              delivery_info, properties, payload = q.pop(ack: ack)

              if payload
                result = nil

                debug "recieve ##{delivery_info.delivery_tag.to_i} #{payload.inspect}"
                result = run_instance delivery_info, properties, payload
                debug "done ##{delivery_info.delivery_tag.to_i}"

                break if result == :shutdown
              else
                sleep config.pool_timeout
              end
            end
          end

          def run_instance(delivery_info, properties, payload)
            body = try_build_from_model(payload) ||
              Common::AMQP::Message.deserialize(payload, properties)

            with_middleware(:recieving, payload: body) do |opts|
              new.tap do |inst|
                inst.properties    = properties
                inst.delivery_info = delivery_info
              end.perform opts[:payload]
            end
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
