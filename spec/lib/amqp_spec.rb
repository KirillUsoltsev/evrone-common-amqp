require 'spec_helper'

describe Evrone::Common::AMQP do
  let(:amqp) { described_class }
  subject { amqp }

  its(:config)    { should be }
  its(:session)   { should be }
end
