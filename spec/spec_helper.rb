require File.expand_path '../../lib/evrone/common/amqp', __FILE__

require 'rspec/autorun'

Dir[File.expand_path("../..", __FILE__) + "/spec/support/**.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rr

  config.after(:suite) do
    Evrone::Common::AMQP.close
  end
end
