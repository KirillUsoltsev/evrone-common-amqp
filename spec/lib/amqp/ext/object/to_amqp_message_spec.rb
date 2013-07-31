require 'spec_helper'

describe Object do
  let(:object) { Object.new }

  context "to_amqp_message" do
    let(:options) { { param: :key } }
    subject { object.to_amqp_message options }

    it { should be_an_instance_of(Evrone::Common::AMQP::Message) }
    its("body.object") { should eq object }
    its(:options)      { should eq options }
  end
end
