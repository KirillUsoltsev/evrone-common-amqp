require 'optparse'
require 'ostruct'

trap "INT" do
  Evrone::Common::AMQP.shutdown
end

module Evrone
  module Common
    module AMQP
      class CLI

        def initialize
          @options = parse_options
        end

        def run
          require_before_executing
          load_consumers
          consumers = find_consumers.inject({}) do |a,c|
            a[c] = 2
            a
          end

          Common::AMQP::Executor::Celluloid.spawn consumers
        end

        private

          def find_consumers
            Evrone::Common::AMQP::Consumer.classes.inject([]) do |a,c|
              c = Kernel.const_get(c)
              a << c if c.method_defined? :perform
              a
            end.uniq
          end

          def load_consumers
            if l = @options[:load_from]
              path = File.expand_path(l, Dir.pwd)
              Dir["#{path}/**.rb"].each do |f|
                load f
              end
            end
          end

          def require_before_executing
            if r = @options[:require]
              require File.expand_path(r, Dir.pwd)
            end
          end

          def parse_options
            options = {}

            OptionParser.new do |opts|
              opts.banner = "Usage: amqp_consumers [options]"

              opts.on("-r", "--require FILE", String, 'Require file before executing') do |r|
                options[:require] = r
              end

              opts.on("-l", "--load DIR", "Load consumers from directory") do |l|
                options[:load_from] = l
              end

              opts.on("-c", "--consumer CONSUMER[,NUM]", "a", "b") do |l|
                name,num = l.split(",")
                num ||= 1
                options[:consumers] ||= []
                options[:consumers] << [name, num.to_i]
              end
            end.parse!

            options
          end

      end
    end
  end
end
