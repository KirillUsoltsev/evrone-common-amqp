require 'spec_helper'
require 'timeout'
require 'thread'

describe Evrone::Common::AMQP::Session do
  let(:sess) { described_class.new }
  let(:queue_name) { 'foo' }
  let(:exch_name)  { 'bar' }

  subject { sess }

  before { sess.open  }
  after  { sess.close }

  context "open" do
    its("conn.status") { should eq :open }
    its(:open?)        { should be }
  end

  context "should reuse connection" do
    before do
      @id = sess.conn.object_id
    end
    its("conn.object_id") { should eq @id }
  end

  context "should reuse channel" do
    before do
      @id = sess.channel.id
    end
    its("channel.id") { should eq @id }
  end

  it 'channel by default should eq connection default channel', ruby: true do
    expect(sess.channel.id).to eq sess.conn.default_channel.id
  end

  context "with_channel" do
    before do
      @default = sess.channel.id
    end

    it "should create and close a new channel" do
      sess.with_channel do
        expect(sess.channel.id).to_not eq @default
      end
      expect(sess.channel.id).to eq @default
    end
  end

  context "close" do
    it "should close connection" do
      expect{ sess.close }.to change{ sess.open? }.from(true).to(false)
    end
  end

  context "declare_exchange" do
    let(:channel) { sess.conn.create_channel }
    let(:options) {{}}
    let(:exch)    { sess.declare_exchange exch_name, options.merge(channel: channel) }
    subject { exch }

    after {
      delete_exchange exch
      channel.close
    }

    it{ should be }

    context "by default", ruby: true do
      its(:name)         { should eq exch_name }
      its(:type)         { should eq :topic }
      its(:durable?)     { should be_true   }
      its(:auto_delete?) { should be_false  }
      its("channel.id")  { should eq sess.channel.id }
    end

    context "when exchange name is nil should use default_exchange_name" do
      let(:exch) { sess.declare_exchange nil, options }
      its(:name) { should eq 'amq.topic' }
    end

    context "when pass durable: false" do
      let(:options) { { durable: false } }
      its(:durable?) { should be_false }
    end

    context "when pass auto_delete: true" do
      let(:options) { { auto_delete: true } }
      its(:auto_delete?) { should be_true }
    end

    context "when pass type: :fanout" do
      let(:options) { { type: :fanout } }
      its(:type) { should eq :fanout }
    end

    context "when pass :channel" do
      let(:ch)      { sess.conn.create_channel }
      let(:options) { { channel: ch } }
      its("channel.id") { should eq ch.id }
    end
  end

  context "declare_queue" do
    let(:options) {{}}
    let(:queue)   { sess.declare_queue queue_name, options }
    subject { queue }

    after { delete_queue queue }

    it{ should be }

    context "by default" do
      its(:name)         { should eq queue_name }
      its(:durable?)     { should be_true   }
      its(:auto_delete?) { should be_false  }
      its(:exclusive?)   { should be_false  }
      its("channel.id")  { should eq sess.channel.id }
    end

    context 'when queue name is nil should use generated name' do
      let(:queue) { sess.declare_queue nil, options }
      its(:name) { should match(/amq\.gen/) }
    end

    context "when pass durable: false" do
      let(:options) { { durable: false } }
      its(:durable?) { should be_false }
    end

    context "when pass auto_delete: true" do
      let(:options) { { auto_delete: true } }
      its(:auto_delete?) { should be_true }
    end

    context "when pass exclusive: true" do
      let(:options) { { exclusive: true } }
      its(:exclusive?) { should  be_true }
    end

    context "when pass :channel" do
      let(:ch)      { sess.conn.create_channel }
      let(:options) { { channel: ch } }
      its("channel.id") { should eq ch.id }
    end
  end
end
