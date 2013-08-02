require 'spec_helper'

describe Evrone::Common::AMQP::Message do
  let(:body)     { 'body' }
  let(:options)  { nil }
  let(:message)  { described_class.new body, options }

  subject { message }

  its(:body)         { should eq body }
  its(:content_type) { should be_nil }
  its(:options)      { should eq({}) }

  context "serialize" do

    subject { message.serialize }

    before { subject }

    context 'using to_json method' do
      let(:body) { { 'key' => 'value' } }

      it { should eq body.to_json }
      it "content_type" do
        expect(message.content_type).to eq 'application/json'
      end
    end

    context 'strings' do
      it { should eq body }
      it "content_type" do
        expect(message.content_type).to eq 'text/plain'
      end
    end
  end

  context 'deserializer' do
    subject { described_class.deserialize message, properties }

    context 'from json string' do
      let(:message)    { object.to_json  }
      let(:object)     { { 'key' => 'value' } }
      let(:properties) { { content_type: 'application/json' } }

      it { should eq object }
    end

    context 'form plain text' do
      let(:message) { 'text' }
      let(:properties) { { content_type: 'text/plain' } }

      it { should eq message }
    end
  end

end
