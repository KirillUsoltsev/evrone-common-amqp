require 'spec_helper'

describe Evrone::Common::AMQP::Connection do
  let(:conn) { described_class.new }
  subject { conn }

  after do
    conn.close
  end

  context "open" do
    before { conn.open }

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
    before { conn.open }

    it "should close channel" do
      expect{ conn.close }.to change{ conn.channel }.to(nil)
    end

    it "should close connection" do
      expect{ conn.close }.to change{ conn.conn }.to(nil)
    end
  end

  context "publish" do
    subject { conn.publish "foo", "message" }
    before { conn.open }
    it { should be }
  end
end
