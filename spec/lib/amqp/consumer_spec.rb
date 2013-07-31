require 'spec_helper'

describe Evrone::Common::AMQP::Consumer do

  class ConsumerTest
    include Evrone::Common::AMQP::Consumer
  end

  let(:consumer) { ConsumerTest.new }
  subject { consumer }

  context '(configuration)' do
    let(:consumer_class) { consumer.class }
    subject { consumer_class }

    before { consumer_class.reset_configuration! }

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

end
