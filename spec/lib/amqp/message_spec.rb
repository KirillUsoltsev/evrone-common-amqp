require 'spec_helper'

describe Evrone::Common::AMQP::Message do
  let(:body)            { { foo: :bar   } }
  let(:message_options) { { param: :key } }
  let(:message)         { described_class.new body, message_options }
  subject { message }

  context "to_json" do
    subject { message.to_json }
    it { should eq "{\"foo\":\"bar\"}" }

    context "with existing 'to_json' method" do
      before do
        def body.to_json
          "to_json method"
        end
      end
      it { should eq 'to_json method' }
    end
  end

  context "routing_key" do
    let(:message_options) { { routing_key: "key" } }
    its(:routing_key)     { should eq 'key' }
  end

  context "publish" do
    let(:exch_name) { 'foo' }
    let(:exch)      { conn.channel.exchanges[exch_name] }
    let(:conn)      { Evrone::Common::AMQP.open }
    let(:type)      { nil }
    let(:publish)   { message.publish exch_name, type }
    subject { publish }

    context "by default" do
      before do
        mock(message.connection).publish("foo", anything, hash_including(type: nil))
      end
      it { should be }
    end

    context "when pass type value" do
      let(:type) { :some_value }
      before do
        mock(message.connection).publish("foo", anything, hash_including(type: :some_value))
      end
      it { should be }
    end

    context "when pass empty exchange name and define them in class" do
      let(:exch_name) { nil }
      before do
        message.class.exchange :baz
        mock(message.connection).publish("baz", anything, anything)
      end
      it{ should be }
    end

    context "when pass empty exchange type and define them in class" do
      before do
        message.class.exchange type: :fanout
        mock(message.connection).publish(anything, anything, hash_including(type: :fanout))
      end
      it { should be }
    end

    context "should merge instance options with class defined options" do
      let(:message_options) { { foo: :bar } }
      before do
        message.class.exchange some_key: :some_value
        mock(message.connection).publish(anything, anything, hash_including({foo: :bar, some_key: :some_value }))
      end
      it { should be }
    end

    context "when define routing key as method and pass they into message options" do
      let(:message_options) { { routing_key: "key" } }
      before do
        def message.routing_key
          'changed key'
        end
        mock(message.connection).publish(anything, anything, hash_including( routing_key: "changed key" ))
      end
      it { should be }
    end
  end

end
