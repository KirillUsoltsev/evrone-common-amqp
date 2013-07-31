require 'spec_helper'
require 'timeout'
require 'thread'

describe Evrone::Common::AMQP::Connection do
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

    its(:message_count) { should eq 1 }
    its("pop.last")     { should eq message }
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

    it "should subscribe to qeuue and receive message" do
      collected = []
      Timeout.timeout(5) do
        conn.subscribe exch_name, queue_name do |received|
          collected << received
          described_class.shutdown

          delete_queue queue
          delete_exchange exch
          ch.close
        end
      end
    end
  end
end
