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

describe "Run in multithread environment" do
  let(:c_first) { Evrone::Alice }
  let(:c_last)  { Evrone::Bob }
  let(:sess)    { Evrone::Common::AMQP.open }
  let(:ch)      { sess.conn.create_channel }

  let(:x_first) { sess.send :declare_exchange, c_first.exchange_name, channel: ch }
  let(:q_first) { sess.send :declare_queue, c_first.queue_name, channel: ch }
  let(:x_last)  { sess.send :declare_exchange, c_last.exchange_name, channel: ch }
  let(:q_last)  { sess.send :declare_queue, c_last.queue_name, channel: ch }

  before do
    [x_first, x_last, q_first, q_last]
    $mtest_collected = []
    $mtest_mutex = Mutex.new
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
    ths = (0..6).map do |i|
      klass = (i % 2 == 0) ? Evrone::Alice : Evrone::Bob
      Thread.new do
        klass.subscribe
      end
    end
    sleep 0.25

    30.times do |n|
      Evrone::Alice.publish "n#{n}"
    end
    sleep 3

    Evrone::Common::AMQP.shutdown
    Timeout.timeout(10) { ths.map{|i| i.join } }

    expect($mtest_collected.sort).to eq (0..29).map{|i| "n#{i}" }.sort
  end

end
