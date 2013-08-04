require 'spec_helper'
require 'timeout'

describe Evrone::Common::AMQP::Supervisor::Threaded do
  let(:superviser) { described_class.new }
  let(:runner)     {
    Struct.new(:timeout, :error) do
      def run
        sleep timeout
        raise "EXCEPTION" if error
      end
    end
  }

  it { should be }

  it "should add a new task" do
    expect{
      superviser.add runner.new(1, false), :run, 1
    }.to change { superviser.size }.from(0).to(1)
  end

  context "run" do
    let(:mutex)     { Mutex.new }
    let(:collected) { [] }
    let(:len)       { 1 }
    let(:runner)    {
      Proc.new do
        id = Thread.current[:id]
        mutex.synchronize do
          collected.push id
        end
        sleep 1
      end
    }

    before do
      len.times {|n| superviser.add runner, :call, n + 1 }
      expect(superviser.size).to eq len
    end

    context "start one task" do
      it "should be" do
        timeout 2 do
          superviser.run_async
          sleep 0.2
          superviser.shutdown
          expect(collected).to eq [1]
        end
      end
    end

    context "start 5 tasks" do
      let(:len) { 5 }

      it "should be", slow: true do
        timeout 10 do
          superviser.run_async
          sleep 0.2
          superviser.shutdown
          expect(collected.sort).to eq [1,2,3,4,5]
        end
      end
    end

    context "restart broken tasks" do
      let(:len) { 2 }
      let(:runner) {
        Proc.new do
          sleep 0.1
          id = Thread.current[:id]
          mutex.synchronize do
            collected.push id
          end
          raise "ERROR SIMULATION"
        end
      }
      it "should be" do
        timeout 10 do
          superviser.run_async
          sleep 2.2
          while !collected.empty?
            first, second = collected.shift, collected.shift
            expect([first,second].sort).to eq [1,2]
          end
        end
      end
    end

    def timeout(val, &block)
      Timeout.timeout(val, &block)
    end
  end

end

