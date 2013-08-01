require 'spec_helper'

describe Evrone::Common::AMQP::Message do
  let(:body)            { { foo: :bar } }
  let(:routing_key)     { 'routing.key' }
  let(:message_options) { { routing_key: routing_key } }
  let(:message)         { described_class.new body, message_options }

  subject { message }

  its(:routing_key) { should eq routing_key }

  context "when body is string" do
    let(:body) { 'string' }
    its(:serialized)    { should eq 'string' }
    its(:content_type)  { should eq 'text/plain' }
  end

  context "when body has to_json method" do
    before do
      mock(body).to_json { 'to json' }
    end
    its(:serialized)    { should eq 'to json' }
    its(:content_type)  { should eq 'application/json' }
  end

  context 'deserialize' do
    let(:body) { described_class.const_get(:Body) }
    let(:hash) { { 'key' => 'value'} }

    it "string" do
      expect(
        body.deserialize('foo', content_type: 'text/plain')
      ).to eq 'foo'
    end

    it "Hash" do
      expect(
        body.deserialize(hash.to_json, content_type: "application/json")
      ).to eq hash
    end

    it "when pass :model option" do
      mock(Hash).from_json(hash.to_json) { hash }
      expect(
        body.deserialize(hash.to_json, {}, {model: Hash})
      ).to eq hash
    end
  end

  context "publish" do
    let(:conn)       { Evrone::Common::AMQP.open }
    let(:exch_name)  { 'foo' }
    let(:queue_name) { 'bar' }
    let(:ch)         { conn.conn.create_channel }
    let(:exch_options) { { type: :direct } }
    let(:exch)       { conn.declare_exchange exch_name,  exch_options.merge(channel: ch) }
    let(:queue)      { conn.declare_queue    queue_name, channel: ch }

    before { conn.open }

    after do
      delete_queue queue
      delete_exchange exch
      conn.close
    end

    it "should delivery message" do
      queue.bind(exch, routing_key: routing_key)
      sleep 0.25
      message.publish exch_name, exch_options
      sleep 0.25
      delivery_info, properties, payload = queue.pop
      expect(payload).to eq body.to_json
      expect(properties[:content_type]).to eq 'application/json'
      expect(delivery_info.routing_key).to eq routing_key
    end
  end
end
