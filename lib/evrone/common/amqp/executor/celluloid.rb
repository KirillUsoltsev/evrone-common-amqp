require 'thread'
require 'celluloid'

trap("INT") { Evrone::Common::AMQP.shutdown }

module Evrone
  module Common
    module AMQP
      module Executor
        module Celluloid

          class << self

            def spawn_async(workers)
              spawn workers, async: true
            end

            def spawn(workers, options = {})
              async = options.key?(:async) ? options[:async] : false

              #Common::AMQP.open

              supervisor = ::Celluloid::SupervisionGroup.run!

              workers.each_pair do |klass, size|
                size.times do |n|
                  name = "#{klass.consumer_name}:#{n}"
                  supervisor.supervise_as name, Worker, klass, n
                end
              end

              if !async
                ::Celluloid.sleep 1 while !Common::AMQP.shutdown?
              end

              #::Celluloid.shutdown
            end

          end

          class Worker

            include ::Celluloid
            include Common::AMQP::Logger

            def initialize(klass, number)
              @number = number
              @klass  = klass

              exclusive do
                Common::AMQP.open
              end

              async.spawn
            end

            def spawn
              Thread.current[:amqp_consumer_number] = @number
              Thread.current[:amqp_consumer_id]     = "#{@klass.to_s}##{@number}"

              warn "spawn"
              @klass.subscribe
            end
          end

        end
      end
    end
  end
end
