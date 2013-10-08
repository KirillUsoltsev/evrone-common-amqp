require 'spec_helper'

describe Evrone::Common::AMQP::Config do
  let(:config) { described_class.new }

  context '(callbacks)' do
    %w{ before after }.each do |p|
      %w{ subscribe recieve publish }.each do |m|
        name = "#{p}_#{m}"
        it name do
          config.public_send name do |value|
            value
          end

          val = config.callbacks[name.to_sym].call("value")
          expect(val).to eq 'value'
        end
      end
    end
  end
end
