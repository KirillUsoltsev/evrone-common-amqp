require 'thread'

module Evrone
  module Common
    module AMQP
      class Supervisor::Threaded

        include Common::AMQP::Logger

        POOL_INTERVAL = 1

        Task = Struct.new(:object, :method, :id) do

          attr_accessor :thread

          def alive?
            !!(thread && thread.alive?)
          end

          def inspect
            %{#<#{self.class.to_s} object=#{object.to_s} method=#{method.inspect} id=#{id.inspect} alive=#{alive?}>}
          end
        end

        def initialize
          @tasks    = Queue.new
          @shutdown = false
        end

        def add(object, method, id)
          @tasks.push Task.new(object, method, id)
        end

        def size
          @tasks.size
        end

        def shutdown?
          @shutdown
        end

        def shutdown
          @shutdown = true
        end

        def pool_async
          Thread.new { pool }
        end

        def pool
          loop do

            task = @tasks.pop

            if shutdown?
              task.join
            else
              unless task.alive?
                log_thread_error task.thread
                warn "spawn #{task.inspect}"
                create_thread(task)
              end
              @tasks.push task
            end

            sleep POOL_INTERVAL
          end
        end

        private

          def create_thread(task)
            task.thread = Thread.new(task) do |t|
              Thread.current[:id] = t.id
              t.object.send t.method
            end
            task
          end

          def log_thread_error(thread)
            return unless thread

            backtrace = thread.backtrace
            error = begin
                      thread.value
                    rescue Exception => e
                      e
                    end
            if error
              warn(error)
              warn(backtrace)
            end
          end

      end
    end
  end
end
