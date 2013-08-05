require 'spec_helper'
require 'timeout'

describe Evrone::Common::AMQP::Supervisor::Threaded, jruby: true do
  let(:supervisor) { described_class.new }
  let(:runner)     {
    Struct.new(:timeout, :error) do
      def run
        sleep timeout
        raise IgnoreMeError if error
      end
    end
  }

  after { Evrone::Common::AMQP.config.reset! }
  before { Evrone::Common::AMQP.config.reset! }

  it { should be }

  it "should add a new task" do
    expect{
      supervisor.add runner.new(1, false), :run, 1
    }.to change { supervisor.size }.from(0).to(1)
  end

  context "run" do
    let(:mutex)     { Mutex.new }
    let(:collected) { [] }
    let(:len)       { 1 }
    let(:runner)    {
      Proc.new do
        id = Thread.current[:consumer_id]
        mutex.synchronize do
          collected.push id
        end
        sleep 1
      end
    }

    before do
      len.times {|n| supervisor.add runner, :call, n + 1 }
      expect(supervisor.size).to eq len
    end

    context "start one task" do
      it "should be" do
        timeout 2 do
          th = supervisor.run_async
          sleep 0.2
          supervisor.shutdown
          timeout(10) { th.join }
          expect(collected).to eq [1]
        end
      end
    end

    context "start 5 tasks" do
      let(:len) { 5 }

      it "should be", slow: true do
        timeout 10 do
          th = supervisor.run_async
          sleep 0.2
          supervisor.shutdown
          timeout(10) { th.join }
          expect(collected.sort).to eq [1,2,3,4,5]
        end
      end
    end

    context "restart broken tasks" do
      let(:len) { 2 }
      let(:runner) {
        Proc.new do
          sleep 0.1
          id = Thread.current[:consumer_id]
          mutex.synchronize do
            collected.push id
          end
          raise IgnoreMeError
        end
      }
      it "should be" do
        timeout 10 do
          th = supervisor.run_async
          sleep 2.2
          supervisor.shutdown
          timeout(10) { th.join }
          while !collected.empty?
            first, second = collected.shift, collected.shift
            expect([first,second].sort).to eq [1,2]
          end
        end
      end
    end

    context "raise when attemts limit reached" do
      let(:runner) {
        Proc.new do
          raise IgnoreMeError
        end
      }

      it "should be" do
        Evrone::Common::AMQP.configure do |c|
          c.spawn_attempts = 1
        end
        th = supervisor.run_async
        timeout 10 do
          expect {
            th.join
          }.to raise_error(Evrone::Common::AMQP::Supervisor::Threaded::SpawnAttemptsLimitReached)
        end
      end
    end

    def timeout(val, &block)
      Timeout.timeout(val, &block)
    end
  end

end

