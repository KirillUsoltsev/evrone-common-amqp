require 'thread'
require 'celluloid'

module Evrone
  module Common
    module AMQP
      module Celluloid

        ::Celluloid.logger = Common::AMQP.config.logger

        trap("INT") { Evrone::Common::AMQP.shutdown }

        class << self

          def spawn_async(workers)
            Common::AMQP.open

            supervisor = ::Celluloid::SupervisionGroup.run!

            workers.each_pair do |klass, size|
              size.times do |n|
                name = "#{klass.consumer_name}:#{n}"
                supervisor.supervise_as name, Worker, klass, n
              end
            end
          end

          def spawn(*args)
            spawn_async(*args).each(&:value)
          end

        end

        class Worker

          include ::Celluloid
          include ::Celluloid::Logger

          #task_class TaskThread

          def initialize(klass, number)
            @number = number
            @klass  = klass
            async.spawn
          end

          def spawn
            info "spawn task ##{@number} #{@klass.to_s}"
            @klass.subscribe
          end
        end

      end
    end
  end
end