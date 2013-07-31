require 'spec_helper'
require 'timeout'
require 'thread'

describe Evrone::Common::AMQP::Session do
  let(:conn) { described_class.new }
  let(:queue_name) { 'foo' }
  let(:exch_name)  { 'bar' }

  subject { conn }

  before { conn.open  }
  after  { conn.close }

  context "open" do
    subject { conn.open }

    its("conn.status") { should eq :open }
    its(:open?)        { should be }
  end

  context "should reuse connection" do
    before do
      @id = conn.conn.object_id
      conn.open
    end
    its("conn.object_id") { should eq @id }
  end

  context "should reuse channel" do
    before do
      @id = conn.channel.id
    end
    its("channel.id") { should eq @id }
  end

  context "channel" do
    subject { conn.channel.id }
    it { should eq conn.conn.default_channel.id }
  end

  context "with_channel" do
    before do
      @default = conn.channel.object_id
    end

    it "should create and close a new channel" do
      conn.with_channel do
        expect(conn.channel.object_id).to_not eq @default
      end
      expect(conn.channel.object_id).to eq @default
    end
  end

  context "close" do
    it "should close connection" do
      expect{ conn.close }.to change{ conn.conn }.to(nil)
    end

    it "should change open? to false" do
      expect{ conn.close }.to change{ conn.open? }.from(true).to(nil)
    end
  end

  context "publish" do
    let(:message)     { '[publish] message' }
    let(:ch)          { conn.conn.create_channel }
    let(:queue)       { conn.declare_queue    queue_name, channel: ch }
    let(:exch)        { conn.declare_exchange exch_name,  channel: ch }
    let(:routing_key) { 'routing_key' }

    before do
      queue.bind exch, routing_key: routing_key
      conn.publish exch_name, message, routing_key: routing_key
      sleep 0.25
    end

    after do
      delete_queue queue
      delete_exchange exch
      ch.close
    end

    subject { queue }

    its(:message_count)          { should eq 1 }
    its("pop.last")              { should eq message }
    its("pop.first.routing_key") { should eq routing_key }
  end

  context "subscribe" do
    let(:message)     { '[subscribe] message' }
    let(:ch)          { conn.conn.create_channel }
    let(:queue)       { conn.declare_queue    queue_name, channel: ch }
    let(:exch)        { conn.declare_exchange exch_name,  channel: ch }

    let(:routing_key) { 'routing_key' }

    before do
      queue.bind exch, routing_key: routing_key
      exch.publish(message, routing_key: routing_key)
      sleep 0.25
    end

    context "queue" do
      subject { queue }

      after do
        delete_queue queue
        delete_exchange exch
        ch.close
      end

      its(:message_count) { should eq 1 }
      its("pop.last")     { should eq message }
    end

    it "should subscribe to queue and receive message" do
      collected = []
      Timeout.timeout(5) do
        conn.subscribe exch_name, queue_name do |_, _, received|
          collected << received
          described_class.shutdown

          delete_queue queue
          delete_exchange exch
          ch.close
        end
      end
      expect(collected).to eq [message]
    end
  end

  context "declare_exchange" do
    let(:options) {{}}
    let(:exch)    { conn.declare_exchange exch_name, options }
    subject { exch }

    after { delete_exchange exch }

    it{ should be }

    context "by default" do
      its(:type)         { should eq :topic }
      its(:durable?)     { should be_true   }
      its(:auto_delete?) { should be_false  }
      its("channel.id")  { should eq conn.channel.id }
    end

    context "when pass durable: false into options" do
      let(:options) { { durable: false } }
      its(:durable?) { should be_false }
    end

    context "when pass auto_delete: true into options" do
      let(:options) { { auto_delete: true } }
      its(:auto_delete?) { should be_true }
    end

    context "when pass type: :fanout into options" do
      let(:options) { { type: :fanout } }
      its(:type) { should eq :fanout }
    end

    context "when pass :channel into options" do
      let(:ch)      { conn.conn.create_channel }
      let(:options) { { channel: ch } }
      its("channel.id") { should eq ch.id }
    end
  end

  context "declare_queue" do
    let(:options) {{}}
    let(:queue)   { conn.declare_queue queue_name, options }
    subject { queue }

    after { delete_queue queue }

    it{ should be }

    context "by default" do
      its(:durable?)     { should be_true   }
      its(:auto_delete?) { should be_false  }
      its(:exclusive?)   { should be_false  }
      its("channel.id")  { should eq conn.channel.id }
    end

    context "when pass durable: false into options" do
      let(:options) { { durable: false } }
      its(:durable?) { should be_false }
    end

    context "when pass auto_delete: true into options" do
      let(:options) { { auto_delete: true } }
      its(:auto_delete?) { should be_true }
    end

    context "when pass exclusive: true into options" do
      let(:options) { { exclusive: true } }
      its(:exclusive?) { should  be_true }
    end

    context "when pass :channel into options" do
      let(:ch)      { conn.conn.create_channel }
      let(:options) { { channel: ch } }
      its("channel.id") { should eq ch.id }
    end
  end
end
