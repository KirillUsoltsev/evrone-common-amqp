require 'spec_helper'

describe Evrone::Common::AMQP::WithMiddleware do
  let(:object) { Object.new.extend described_class }

  Foo = Struct.new(:app, :id) do
    def call(env)
      env << "called"
      app.call env
    end
  end

  before { Evrone::Common::AMQP.config.reset! }
  after  { Evrone::Common::AMQP.config.reset! }

  context 'with_middleware' do
    it "should be successfull" do
      Evrone::Common::AMQP.configure do |c|
        c.publishing do
          use Foo, :id
        end
      end

      collected = ""
      object.with_middleware(:publishing, "") do |env|
        collected << env
      end
      expect(collected).to eq 'called'
    end
  end
end

