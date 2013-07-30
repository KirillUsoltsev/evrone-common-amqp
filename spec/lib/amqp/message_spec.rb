require 'spec_helper'

describe Evrone::Common::AMQP::Message do
  let(:body)    { { foo: :bar   } }
  let(:options) { { param: :key } }
  let(:message) { described_class.new body, options }
  subject { message }

  its(:routing_key) { should be_nil }

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

  context "publish" do
    subject { message.publish 'foo' }
    before { Evrone::Common::AMQP.open }
    it { should be }

    context "with exhange type" do
      subject { message.publish 'foo', :fanout }
    end
  end

  context "routing_key" do
    let(:options)     { { routing_key: "key" } }
    its(:routing_key) { should eq 'key' }
  end
end
