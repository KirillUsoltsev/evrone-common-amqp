require 'spec_helper'
require 'timeout'

describe Evrone::Common::AMQP::Consumer do

  class ConsumerTest
    include Evrone::Common::AMQP::Consumer
  end

  let(:consumer) { ConsumerTest.new }
  let(:consumer_class) { consumer.class }

  subject { consumer }

  before { consumer_class.reset_configuration! }

  context '(configuration)' do
    subject { consumer_class }

    context "exchange_name" do
      subject { consumer_class.exchange_name }

      it 'by default should eq amq.topic' do
        expect(subject).to eq 'amq.topic'
      end

      it "when set exchange :type to :direct should eq amq.direct" do
        consumer_class.exchange type: :direct
        expect(subject).to eq 'amq.direct'
      end

      it "when set name should be" do
        consumer_class.exchange :foo
        expect(subject).to eq :foo
      end
    end

    context "queue_name" do
      subject{ consumer_class.queue_name }
      it 'by default should be nil' do
        expect(subject).to be_nil
      end

      it "when set name should be" do
        consumer_class.queue :bar
        expect(subject).to eq :bar
      end
    end

    %w{ queue exchange }.each do |m|
      context "#{m}_options" do
        subject { consumer_class.send "#{m}_options" }
        it 'by default should eq {}' do
          expect(subject).to eq({})
        end

        it "when set #{m} options should be" do
          consumer_class.send(m, durable: true)
          expect(subject).to eq(durable: true)
        end
      end
    end

    %w{ routing_key headers }.each do |m|
      context m do
        subject { consumer_class.send m }

        it 'by default should be nil' do
          expect(subject).to be_nil
        end

        it "when set #{m} should be" do
          consumer_class.send(m, key: :value)
          expect(subject).to eq(key: :value)
        end
      end
    end
  end

  context "consume" do
    let(:sess)        { consumer_class.session }
    let(:ch)          { sess.conn.create_channel }
    let(:exch_name)   { :foo }
    let(:queue_name)  { :bar }
    let(:routing_key) { 'routing.key' }
    let(:message)     { { 'key' =>  'value' } }

    let(:queue)       { sess.declare_queue queue_name }
    let(:exch)        { sess.declare_exchange exch_name }
    let(:collected)   { [] }

    before do
      consumer_class.exchange    exch_name
      consumer_class.queue       queue_name
      consumer_class.routing_key routing_key

      sess.open
      queue.bind exch, routing_key: routing_key
      body = Evrone::Common::AMQP::Message::Body.new(message)
      exch.publish body.serialized, routing_key: routing_key, content_type: body.content_type
      sleep 0.25
    end

    after do
      sess.close
    end

    it "should receive message" do
      mock(consumer_class).create_object.mock!.perform(anything, anything) do |payload|
        collected << payload
        sess.class.shutdown
        delete_queue queue
        delete_exchange exch
        ch.close
      end
      Timeout.timeout(5) do
        consumer_class.consume
      end
      expect(collected).to eq [message]
    end

  end

end
