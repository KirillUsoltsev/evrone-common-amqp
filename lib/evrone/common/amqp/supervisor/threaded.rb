require 'thread'

module Evrone
  module Common
    module AMQP
      class Supervisor::Threaded

        include Common::AMQP::Logger

        POOL_INTERVAL = 0.5

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
          @tasks    = Array.new
          @shutdown = false
        end

        def add(object, method, id)
          @tasks.push Task.new(object, method, id).freeze
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

        def run_async
          Thread.new { run }.tap{|t| t.abort_on_exception = true }
        end

        def run
          start_all_threads

          loop do
            task = @tasks.shift
            break unless task

            case
            when shutdown?
              task.thread.join if task.alive?
            when task.alive?
              @tasks.push task
            else
              log_thread_error task
              @tasks.push create_thread(task)
            end

            sleep POOL_INTERVAL unless shutdown?
          end
        end

        private

          def start_all_threads
            started_tasks = Array.new
            while task = @tasks.shift
              started_tasks.push create_thread(task)
            end
            while task = started_tasks.shift
              @tasks.push task
            end
          end

          def create_thread(task)
            debug "spawn #{task.inspect}"
            task.dup.tap do |new_task|
              new_task.thread = Thread.new(new_task) do |t|
                Thread.current[:id] = t.id
                t.object.send t.method
              end
              new_task.thread.abort_on_exception = false
              new_task.freeze
            end
          end

          def log_thread_error(task)
            return unless task.thread

            begin
              task.thread.value
            rescue Exception => e
              warn "ERROR: #{e.class.to_s} #{e} in #{task.inspect}"
              warn "BACKTRACE:\n" + e.backtrace.join("\n")
            end
          end

      end
    end
  end
end
