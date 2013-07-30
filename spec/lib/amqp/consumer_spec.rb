require 'spec_helper'


describe Evrone::Common::AMQP::Consumer do
  class TestConsumer
    include Evrone::Common::AMQP::Consumer

    exchange :foo, durable: false
    queue    :bar, exclusive: true

  end

  let(:consumer_class) { TestConsumer }
  let(:consumer)       { consumer_class.new }

  context "configuration" do
    subject { consumer_class.configuration }

    its("queue.name")       { should eq :bar }
    its("queue.options")    { should eq({ exclusive: true }) }
    its("exchange.name")    { should eq :foo }
    its("exchange.options") { should eq({ durable: false }) }
  end
end
