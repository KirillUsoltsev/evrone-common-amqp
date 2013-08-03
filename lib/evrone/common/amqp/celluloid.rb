require 'thread'
require 'celluloid'

trap("INT") { Evrone::Common::AMQP.shutdown }

::Celluloid.logger = Common::AMQP.config.logger

module Evrone
  module Common
    module AMQP
      module Celluloid

        class << self

          def spawn_async(workers)
            spawn workers, async: true
          end

          def spawn(workers, options = {})
            async = options.key?(:async) ? options[:async] : false

            Common::AMQP.open

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

            ::Celluloid.shutdown
          end

        end

        class Worker

          include ::Celluloid
          include ::Celluloid::Logger

          def initialize(klass, number)
            @number = number
            @klass  = klass
            async.spawn
          end

          def spawn
            Thread.current[:actor_number] = @number
            Evrone::Common::AMQP.session.warn "#{@klass.to_s} spawn ##{@number}"
            @klass.subscribe
          end
        end

      end
    end
  end
end
