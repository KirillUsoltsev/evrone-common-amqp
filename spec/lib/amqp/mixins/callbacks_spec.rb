require 'spec_helper'

describe Evrone::Common::AMQP::Callbacks do
  let(:output) { [] }
  let(:object) { Object.new.extend described_class }

  before do
    Evrone::Common::AMQP.config.reset!
    Evrone::Common::AMQP.configure do |c|
      c.before_publish { |v| output << "before:#{v}" }
      c.after_publish  { |v| output << "after:#{v}" }
    end
  end

  after  { Evrone::Common::AMQP.config.reset! }

  context 'run_callbacks' do
    it "should be success" do
      object.run_callbacks :publish, "call" do
        output << "call"
      end
      expect(output).to eq %w{ before:call call after:call }
    end
  end
end

