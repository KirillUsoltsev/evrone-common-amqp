require 'spec_helper'
require 'timeout'
require 'json'

class Evrone::TestConsumer
  include Evrone::Common::AMQP::Consumer

  ack true

  def perform(payload)
    Thread.current[:collected] ||= []
    Thread.current[:collected] << payload
    ack!

    :shutdown if Thread.current[:collected].size == 3
  end
end

describe Evrone::Common::AMQP::Consumer do

  let(:consumer) { Evrone::TestConsumer.new }
  let(:consumer_class) { consumer.class }

  subject { consumer }

  before { consumer_class.reset_consumer_configuration! }

  context '(configuration)' do

    subject { consumer_class }

    its(:config)        { should be_an_instance_of(Evrone::Common::AMQP::Config) }
    its(:consumer_name) { should eq 'test_consumer' }

    context "instance consumer_name" do
      subject { consumer.consumer_name }

      it { should eq 'test_consumer' }

      context "when Thread.current has key :consumer_id" do
        before do
          mock(Thread.current).[](:consumer_id){ '99' }
        end
        it { should eq 'test_consumer.99' }
      end
    end


    context "model" do
      subject { consumer_class.model }

      it "by default should be nil" do
        expect(subject).to be_nil
      end

      it 'when set model should be' do
        consumer_class.model Hash
        expect(subject).to eq Hash
      end
    end

    context "content_type" do

      subject { consumer_class.content_type }

      it "by default should be nil" do
        expect(subject).to be_nil
      end

      it 'when set content type should be' do
        consumer_class.content_type 'foo'
        expect(subject).to eq 'foo'
      end
    end

    context "bind_options" do
      subject { consumer_class.bind_options }

      context "by default should eq {}" do
        it { should eq ({}) }
      end

      context "set routing_key" do
        before { consumer_class.routing_key 'key' }
        it { should eq(routing_key: 'key') }
      end

      context "set routing_key by block" do
        before do
          consumer_class.routing_key { 'key.block' }
        end
        it { should eq(routing_key: 'key.block') }
      end

      context "set headers" do
        before { consumer_class.headers 'key' }
        it { should eq({headers: 'key'}) }
      end

      context "set headers by block" do
        before { consumer_class.headers { 'key.block' } }
        it { should eq(headers: 'key.block') }
      end
    end

    context "ack" do
      subject { consumer_class.ack }

      it "by default should be false" do
        expect(subject).to be_false
      end

      it "when set to true should be true" do
        consumer_class.ack true
        expect(subject).to be_true
      end
    end

    context "exchange_name" do
      subject { consumer_class.exchange_name }

      it 'by default should eq consumer_name' do
        expect(subject).to eq consumer_class.consumer_name
      end

      it "when set name should be" do
        consumer_class.exchange :foo
        expect(subject).to eq :foo
      end

      it "when set by block should be" do
        consumer_class.exchange { 'name.block' }
        expect(subject).to eq 'name.block'
      end
    end

    context "queue_name" do
      subject{ consumer_class.queue_name }
      it 'by default should eq consumer_name' do
        expect(subject).to eq consumer_class.consumer_name
      end

      it "when set name should be" do
        consumer_class.queue :bar
        expect(subject).to eq :bar
      end

      it "when set by block should be" do
        consumer_class.queue { 'name.block' }
        expect(subject).to eq 'name.block'
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

  context "(publish)" do

    context "options" do
      let(:message)          { {"foo" => 1, "bar" => 2} }
      let(:expected_options) { {} }
      let(:options)          { {} }
      let(:x)                { OpenStruct.new name: "name" }

      subject{ consumer_class.publish message, options }

      before do
        mock(consumer_class).declare_exchange { x }
        mock(x).publish(message.to_json, expected_options)
      end

      context "routing_key" do
        context "by default" do
          it { should be }
        end

        context "when exists in configuration" do
          let(:expected_options) { { routing_key: 'routing.key' } }
          before do
            consumer_class.routing_key 'routing.key'
          end
          it { should be }
        end

        context "when exists in options" do
          let(:expected_options) { { routing_key: 'routing.key' } }
          let(:options)          { { routing_key: 'routing.key' } }
          it { should be }
        end

        context "when exists in options and configuration" do
          let(:expected_options) { { routing_key: 'options.key' } }
          let(:options)          { { routing_key: 'options.key' } }
          before do
            consumer_class.routing_key 'configuration.key'
          end
          it { should be }
        end
      end

      context "headers" do
        context "by default" do
          it { should be }
        end

        context "when exists in configuration" do
          let(:expected_options) { { headers: 'key' } }
          before do
            consumer_class.headers 'key'
          end
          it { should be }
        end

        context "when exists in options" do
          let(:expected_options) { { headers: 'key' } }
          let(:options)          { { headers: 'key' } }
          it { should be }
        end

        context "when exists in options and configuration" do
          let(:expected_options) { { headers: 'options' } }
          let(:options)          { { headers: 'options' } }
          before do
            consumer_class.headers 'configuration'
          end
          it { should be }
        end
      end
    end

    context "real run" do
      let(:x_name)  { consumer_class.exchange_name      }
      let(:q_name)  { consumer_class.queue_name         }
      let(:sess)    { consumer_class.session.open       }
      let(:ch)      { sess.conn.create_channel          }
      let(:q)       { sess.declare_queue q_name, channel: ch    }
      let(:x)       { sess.declare_exchange x_name, channel: ch }
      let(:message) { { 'key' => 'value' } }

      after do
        delete_queue q
        delete_exchange x
        sess.close
      end

      before do
        q.bind x
      end

      it "should publish message to exchange using settings from consumer" do
        consumer_class.publish message
        sleep 0.25
        expect(q.message_count).to eq 1
        _, _, expected = q.pop
        expect(expected).to eq message.to_json
      end
    end
  end

  context '(subscribe)' do
    let(:x_name)  { consumer_class.exchange_name      }
    let(:q_name)  { consumer_class.queue_name         }
    let(:sess)    { consumer_class.session.open       }
    let(:ch)      { sess.conn.create_channel          }
    let(:q)       { sess.declare_queue q_name, channel: ch    }
    let(:x)       { sess.declare_exchange x_name, channel: ch }

    after do
      delete_queue q
      delete_exchange x
      sess.close
    end

    before do
      consumer_class.ack true
      q.bind(x)
      3.times { |n| x.publish({"n" => n}.to_json, content_type: "application/json") }
    end

    subject { Thread.current[:collected] }

    it "should receive messages" do
      Timeout.timeout(3) do
        consumer_class.subscribe
      end
      expect(subject).to have(3).items
      expect(subject.map(&:values).flatten).to eq [0,1,2]
    end
  end
end
