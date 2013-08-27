require 'spec_helper'
require 'json'

class FormatterConsumerTest
  include Evrone::Common::AMQP::Consumer

  model Hash
end

describe Evrone::Common::AMQP::Formatter do
  let(:consumer) { FormatterConsumerTest.new }
  subject        { described_class           }

  context "pack" do
    let(:body) { { "a" => 1, "b" => 2 } }

    it "should pack message" do
      expect(subject.pack 'application/json', body).to eq body.to_json
      expect(subject.pack :foo, body).to be_nil
    end

  end

  context "unpack" do
    let(:body) { { "a" => 1, "b" => 2 } }

    before do
      mock(Hash).from_json(body.to_json) { body }
    end

    it "should unpack message" do
      expect(subject.unpack 'application/json', Hash, body.to_json).to eq body
      expect(subject.unpack :foo, Hash, body.to_json).to be_nil
    end

  end

  context "lookup" do

    it "should find format by content type" do
      expect(subject.lookup('application/json').content_type).to eq 'application/json'
      expect(subject.lookup(:foo)).to be_nil
    end

  end

end
