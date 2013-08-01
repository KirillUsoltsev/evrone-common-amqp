require 'spec_helper'
require 'timeout'

describe Evrone::Common::AMQP::Consumer do

  class Evrone::ConsumerTest
    include Evrone::Common::AMQP::Consumer
  end

  let(:consumer) { Evrone::ConsumerTest.new }
  let(:consumer_class) { consumer.class }

  subject { consumer }

  before { consumer_class.reset_consumer_configuration! }

  context "consumer_name" do
    subject { consumer_class.consumer_name }
    it { should eq 'evrone.consumer.test' }
  end

  context '(configuration)' do

    subject { consumer_class }

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

    context "exchange_name" do
      subject { consumer_class.exchange_name }

      it 'by default should eq consumer_name' do
        expect(subject).to eq consumer_class.consumer_name
      end

      it "when set name should be" do
        consumer_class.exchange :foo
        expect(subject).to eq :foo
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
    let(:x_name)  { consumer_class.exchange_name      }
    let(:q_name)  { consumer_class.queue_name         }
    let(:sess)    { consumer_class.session.open       }
    let(:ch)      { sess.conn.create_channel          }
    let(:q)       { sess.declare_queue q_name, channel: ch    }
    let(:x)       { sess.declare_exchange x_name, channel: ch }
    let(:message) { { 'key' => 'value' }              }

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
