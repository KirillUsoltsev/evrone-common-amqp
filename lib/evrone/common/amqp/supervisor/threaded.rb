require 'thread'

module Evrone
  module Common
    module AMQP
      class Supervisor::Threaded

        include Common::AMQP::Logger
        include Common::AMQP::Callbacks

        POOL_INTERVAL = 0.5

        Task = Struct.new(:object, :method, :id) do

          attr_accessor :thread, :attempt, :start_at

          def alive?
            !!(thread && thread.alive?)
          end

          def inspect
            %{#<Task
                 object=#{object.to_s}
                 method=#{method.inspect}
                 id=#{id.inspect}
                 alive=#{alive?}
                 attempt=#{attempt}
                 start_at=#{start_at}> }.gsub("\n", ' ').gsub(/ +/, ' ').strip
          end
        end

        class SpawnAttemptsLimitReached < ::Exception ; end

        class << self

          @@shutdown = false

          def build(tasks)
            supervisor = new
            tasks.each_pair do |k,v|
              v.to_i.times do |n|
                supervisor.add k, :subscribe, n
              end
            end
            supervisor
          end

          def resume
            @@shutdown = false
          end

          def shutdown?
            @@shutdown
          end

          def shutdown
            @@shutdown = true
          end

        end

        def initialize
          self.class.resume
          @tasks = Array.new
        end

        def add(object, method, id)
          @tasks.push Task.new(object, method, id).freeze
        end

        def size
          @tasks.size
        end

        def shutdown?
          self.class.shutdown?
        end

        def shutdown
          self.class.shutdown
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
              log_thread_error task
            when task.alive?
              @tasks.push task
            else
              process_fail task
            end

            sleep POOL_INTERVAL unless shutdown?
          end
        end

        private

          def process_fail(task)
            log_thread_error task
            if check_attempt task
              @tasks.push create_thread(task, task.attempt + 1)
            else
              raise SpawnAttemptsLimitReached
            end
          end

          def start_all_threads
            started_tasks = Array.new
            while task = @tasks.shift
              started_tasks.push create_thread(task, 0)
            end
            while task = started_tasks.shift
              @tasks.push task
            end
          end

          def create_thread(task, attempt)
            attempt = 0 if reset_attempt?(task)
            task.dup.tap do |new_task|
              new_task.thread = Thread.new(new_task) do |t|
                Thread.current[:evrone_amqp_consumer_id] = t.id
                t.object.send t.method
              end
              new_task.thread.abort_on_exception = false
              new_task.attempt = attempt
              new_task.start_at = Time.now
              new_task.freeze
              debug "spawn #{new_task.inspect}"
            end
          end

          def log_thread_error(task)
            return unless task.thread

            begin
              task.thread.value
              nil
            rescue Exception => e
              STDERR.puts "#{e.inspect} in #{task.inspect}"
              STDERR.puts e.backtrace.join("\n")
              run_on_error_callback(e)
              e
            end
          end

          def reset_attempt?(task)
            return true unless task.start_at

            interval = 60
            (task.start_at + interval) < Time.now
          end

          def check_attempt(task)
            task.attempt.to_i <= Common::AMQP.config.spawn_attempts.to_i
          end

      end
    end
  end
end
