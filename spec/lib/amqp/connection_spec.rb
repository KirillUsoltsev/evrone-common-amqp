require 'spec_helper'
require 'timeout'
require 'thread'

describe Evrone::Common::AMQP::Connection do
  let(:conn) { described_class.new }
  subject { conn }

  before { conn.open  }
  after  { conn.close }

  context "open" do
    subject { conn.open }

    its(:conn)         { should be }
    its(:channel)      { should be }
    its("conn.status") { should eq :open }

    context "twice" do
      before do
        @id = conn.conn.object_id
        conn.open
      end
      its("conn.status")    { should eq :open }
      its("conn.object_id") { should eq @id }
    end
  end

  context "close" do
    it "should close connection" do
      expect{ conn.close }.to change{ conn.conn }.to(nil)
    end
  end

  context "publish" do
    let(:message)   { '[publish] message' }
    let(:options)   { {} }
    let(:publish)   { conn.publish exch_name, message, options }
    let(:exch_name) { 'foo' }
    let(:exch)      { conn.channel.exchanges[exch_name] }

    before { publish }
    after  { delete_exchange(exch) }

    context "created exchange" do
      subject { exch }
      it { should be }

      context "params" do
        context "by default" do
          its(:durable?)     { should be_true }
          its(:auto_delete?) { should be_false }
        end

        context "when pass durable: true to options" do
          let(:options)      { { durable: false } }
          its(:durable?)     { should be_false }
        end

        context "when pass auto_delete: true to options" do
          let(:options)      { { auto_delete: true } }
          its(:auto_delete?) { should be_true }
        end
      end

      context "type" do
        context "by default" do
          its(:type) { should eq :topic }
        end

        context "when pass type: :fanout to options" do
          let(:options) { { type: :fanout } }
          its(:type) { should eq :fanout }
        end
      end
    end
  end

  context "subscribe" do
    let(:options)    { {} }
    let(:queue_name) { 'bar' }
    let(:queue)      { conn.channel.queues[queue_name]  }
    let(:exch_name)  { 'foo' }
    let(:exch)       { conn.channel.exchanges[exch_name] }
    let(:collected)  { [] }
    let(:message)    { "[subscribe] message" }
    let(:publish)    { conn.publish exch_name, message   }
    let(:shutdown)   { described_class.shutdown }
    let(:worker)     {
      th = Thread.new do
        conn.subscribe(exch_name, queue_name, options) do |received|
          collected << received
        end
      end
      sleep(run_timeout_from_env || 2)
      th
    }

    it "should receive message" do
      worker
      publish
      sleep(run_timeout_from_env || 3)
      delete_queue(queue)
      delete_exchange(exch)
      shutdown
      timeout { worker.join }
      expect(collected).to include(message)
    end

    context "exchange" do
      subject { exch }
      before  { worker }
      after   {
        delete_queue(queue)
        delete_exchange(exch)
      }

      context "type" do
        subject { exch.type }

        context "by default" do
          it { should eq :topic }
        end

        context "when pass type: :fanout to exchange options" do
          let(:options) { { exchange: { type: :fanout } } }
          it { should eq :fanout }
        end
      end

      context "options" do
        context "by default" do
          its(:durable?)     { should be_true }
          its(:auto_delete?) { should be_false }
        end

        context "when pass durable: false to exchange options" do
          let(:options)      { { exchange: { durable: false } } }
          its(:durable?)     { should be_false }
        end

        context "when pass auto_delete: true to exchange options" do
          let(:options)      { { exchange: { auto_delete: true } } }
          its(:auto_delete?) { should be_true }
        end
      end
    end

    context "queue" do
      subject { queue }
      before  { worker }
      after   {
        delete_queue(queue)
        delete_exchange(exch)
      }

      context "options" do
        context "by default" do
          its(:durable?)     { should be_true }
          its(:auto_delete?) { should be_false }
          its(:exclusive?)   { should be_false }
        end

        context "when pass durable: false to queue options" do
          let(:options)      { { queue: { durable: false } } }
          its(:durable?)     { should be_false }
        end

        context "when pass auto_delete: true to queue options" do
          let(:options)      { { queue: { auto_delete: true } } }
          its(:auto_delete?) { should be_true }
        end

        context "when pass exclusive: true to queue options" do
          let(:options)      { { queue: { exclusive: true } } }
          its(:exclusive?)   { should be_true }
        end
      end
    end

    def timeout(&block)
      Timeout.timeout(run_timeout_from_env || 3, &block)
    end

    def run_timeout_from_env
      if i =  ENV['TEST_RUN_TIMEOUT']
        i.to_i
      end
    end
  end
end
