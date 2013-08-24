require 'spec_helper'
require 'json'

class FormatterConsumerTest
  include Evrone::Common::AMQP::Consumer

  model Hash
end

describe Evrone::Common::AMQP::Formatter do
  subject { described_class }
  let(:consumer) { FormatterConsumerTest.new }

  before do
    described_class.formats.clear
    described_class.define :json do

      content_type 'application/json'

      pack do |val, consumer|
        val.to_json
      end

      unpack do |val, consumer|
        consumer.class.model.from_json val
      end
    end
  end

  context "pack" do
    let(:body) { { "a" => 1, "b" => 2 } }

    it "should pack message" do
      expect(subject.pack 'application/json', consumer, body).to eq body.to_json
      expect(subject.pack :foo, consumer, body).to be_nil
    end

  end

  context "unpack" do
    let(:body) { { "a" => 1, "b" => 2 } }

    before do
      mock(Hash).from_json(body.to_json) { body }
    end

    it "should unpack message" do
      expect(subject.unpack 'application/json', consumer, body.to_json).to eq body
      expect(subject.pack :foo, consumer, body.to_json).to be_nil
    end

  end

  context "content_type" do

    it "should find content type for format" do
      expect(subject.content_type :json).to eq 'application/json'
      expect(subject.content_type :foo).to be_nil
    end

  end

  context "lookup" do

    it "should find format by name" do
      expect(subject.lookup(:json).content_type).to eq 'application/json'
      expect(subject.lookup(:foo)).to be_nil
    end

  end


  context "lookup_by_content_type" do

    it "should find format by content_type" do
      expect(subject.lookup_by_content_type('application/json').name).to eq :json
      expect(subject.lookup_by_content_type(:foo)).to be_nil
    end

  end

end
