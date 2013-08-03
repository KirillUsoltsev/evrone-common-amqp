require 'spec_helper'
require 'thread'
require 'timeout'


class Evrone::Bob
  include Evrone::Common::AMQP::Consumer

  def perform(payload, properties)
    $mtest_mutex.synchronize do
      $mtest_collected << payload
      sleep 0.1
    end
  end
end

class Evrone::Alice
  include Evrone::Common::AMQP::Consumer

  def perform(payload, properties)
    Evrone::Bob.publish payload
    sleep 0.1
  end
end

describe "Run in multithread environment", slow: true do
  let(:num_messages) { 100 }
  let(:c_first) { Evrone::Alice }
  let(:c_last)  { Evrone::Bob }
  let(:sess)    { Evrone::Common::AMQP.open }
  let(:ch)      { sess.conn.create_channel }

  let(:x_first) { sess.send :declare_exchange, c_first.exchange_name, channel: ch }
  let(:q_first) { sess.send :declare_queue, c_first.queue_name, channel: ch }
  let(:x_last)  { sess.send :declare_exchange, c_last.exchange_name, channel: ch }
  let(:q_last)  { sess.send :declare_queue, c_last.queue_name, channel: ch }

  before do
    $mtest_mutex = Mutex.new
    $mtest_collected = []
    [x_first, x_last, q_first, q_last]
  end

  after do
    sess.with_channel do
      [q_first, q_last].each do |q|
        delete_queue q
      end
      [x_first, x_last].each do |x|
        delete_exchange x
      end
    end
    sess.close
  end

  it "should be successfuly" do
    ths = (0..12).map do |i|
      klass = (i % 2 == 0) ? Evrone::Alice : Evrone::Bob
      Thread.new do
        klass.subscribe
      end
    end
    sleep 0.5

    num_messages.times do |n|
      Evrone::Alice.publish "n#{n}"
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
