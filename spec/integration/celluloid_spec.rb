require 'spec_helper'
require 'thread'
require 'timeout'

class Evrone::BobActor
  include Evrone::Common::AMQP::Consumer

  queue    exclusive: true, durable: false
  exchange auto_delete: true, durable: false
  ack      true

  def perform(payload)
    raise "Simulate crash" if Random.new(delivery_info.delivery_tag).rand < 0.2
    $mtest_mutex.synchronize do
      $mtest_collected << payload
      ack!
      sleep 0.1
    end
  end
end

class Evrone::AliceActor
  include Evrone::Common::AMQP::Consumer

  queue    exclusive: true, durable: false
  exchange auto_delete: true, durable: false
  ack      true

  def perform(payload)
    Evrone::BobActor.publish payload
    ack!
    sleep 0.1
  end
end

describe "Run in celluloid environment", slow: true do
  let(:num_messages) { 100 }
  let(:alice)   { Evrone::AliceActor }
  let(:bob)     { Evrone::BobActor }
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
    Evrone::Common::AMQP::Celluloid.spawn_async(alice => 6, bob => 6)
    Celluloid.sleep 0.5

    num_messages.times do |n|
      alice.publish "n#{n}"
    end

    Celluloid.sleep 0.5

    Timeout.timeout(60) do
      loop do
        stop = false
        $mtest_mutex.synchronize do
          puts $mtest_collected.size
          stop = true if $mtest_collected.size >= num_messages
        end
        break if stop
        Celluloid.sleep 2
      end
    end

    Evrone::Common::AMQP.shutdown
    Celluloid.sleep 0.5
    Celluloid.shutdown

    expect($mtest_collected.sort).to eq (0...num_messages).map{|i| "n#{i}" }.sort
  end

end
