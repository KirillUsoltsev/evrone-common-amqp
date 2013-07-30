require 'spec_helper'

describe Evrone::Common::AMQP::Message do
  let(:body)    { { foo: :bar   } }
  let(:options) { { param: :key } }
  let(:message) { described_class.new body, options }
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
    let(:options)     { { routing_key: "key" } }
    its(:routing_key) { should eq 'key' }
  end

  context "publish" do
    let(:exch_name) { 'foo' }
    let(:exch)      { conn.channel.exchanges[exch_name] }
    let(:conn)      { Evrone::Common::AMQP.open }
    let(:publish)   { message.publish exch_name }

    before { conn and publish }
    after  { delete_exchange exch and conn.close }

    it { should be }

    context "exchange" do
      subject { exch }
      its(:type) { should eq :topic }
    end
  end

end
