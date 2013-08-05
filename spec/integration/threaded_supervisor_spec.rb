require 'spec_helper'
require 'thread'
require 'timeout'

class Evrone::BobThreadWithSupervisor
  include Evrone::Common::AMQP::Consumer

  class ErrorSimulation < ::Exception ; end

  queue    exclusive: true, durable: false
  exchange auto_delete: true, durable: false
  ack      true

  def perform(payload)
    $mtest_mutex.synchronize do
      raise IgnoreMeError if Random.new(delivery_info.delivery_tag.to_i).rand < 0.2
      $mtest_collected << payload
      ack!
      sleep 0.1
    end
  end
end

class Evrone::AliceThreadWithSupervisor
  include Evrone::Common::AMQP::Consumer

  queue    exclusive: true, durable: false
  exchange auto_delete: true, durable: false
  ack      true

  def perform(payload)
    Evrone::BobThreadWithSupervisor.publish payload
    ack!
    sleep 0.1
  end
end

describe "Run in multithread environment", slow: true, jruby: true do
  let(:num_messages) { 100 }
  let(:alice)   { Evrone::AliceThreadWithSupervisor }
  let(:bob)     { Evrone::BobThreadWithSupervisor }
  let(:sess)    { Evrone::Common::AMQP.open }
  let(:ch)      { sess.conn.create_channel }

  before do
    $mtest_mutex = Mutex.new
    $mtest_collected = []
  end

  after do
    sess.close
  end

  it "should be successfuly" do

    supervisor = Evrone::Common::AMQP::Supervisor::Threaded.build alice => 6, bob => 6

    supervisor_thread = supervisor.run_async

    sleep 0.5

    num_messages.times do |n|
      alice.publish "n#{n}"
    end

    Timeout.timeout(60) do
      loop do
        stop = false
        $mtest_mutex.synchronize do
          puts $mtest_collected.size
          stop = true if $mtest_collected.size >= num_messages
        end
        break if stop
        sleep 2
      end
    end

    Evrone::Common::AMQP.shutdown
    supervisor.shutdown
    Timeout.timeout(10) { supervisor_thread.join }

    expect($mtest_collected.sort).to eq (0...num_messages).map{|i| "n#{i}" }.sort
  end

end
