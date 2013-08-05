require 'spec_helper'
require 'thread'
require 'timeout'

class Evrone::BobThread
  include Evrone::Common::AMQP::Consumer

  queue    exclusive: true, durable: false
  exchange auto_delete: true, durable: false
  ack      true

  def perform(payload)
    $mtest_mutex.synchronize do
      $mtest_collected << payload
      ack!
      sleep 0.1
    end
  end
end

class Evrone::AliceThread
  include Evrone::Common::AMQP::Consumer

  queue    exclusive: true, durable: false
  exchange auto_delete: true, durable: false
  ack      true

  def perform(payload)
    Evrone::BobThread.publish payload
    ack!
    sleep 0.1
  end
end

describe "Run in multithread environment", slow: true do
  let(:num_messages) { 100 }
  let(:alice)   { Evrone::AliceThread }
  let(:bob)     { Evrone::BobThread }
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
    ths = (0..12).map do |i|
      klass = (i % 2 == 0) ? alice : bob
      Thread.new do
        klass.subscribe
      end
    end
    ths.each{|t| t.abort_on_exception = true }
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
    Timeout.timeout(10) { ths.map{|i| i.join } }

    expect($mtest_collected.sort).to eq (0...num_messages).map{|i| "n#{i}" }.sort
  end

end
