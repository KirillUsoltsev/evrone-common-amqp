require File.expand_path("../amqp/version", __FILE__)
require File.expand_path("../amqp/ext/object/to_amqp_message", __FILE__)

module Evrone
  module Common
    module AMQP
      autoload :Config,     File.expand_path("../amqp/config",     __FILE__)
      autoload :Connection, File.expand_path("../amqp/connection", __FILE__)
      autoload :Consumer,   File.expand_path("../amqp/consumer",   __FILE__)
      autoload :Helper,     File.expand_path("../amqp/helper",     __FILE__)
      autoload :Message,    File.expand_path("../amqp/message",    __FILE__)

      extend self

      def configure
        yield config
      end

      def config
        @config ||= Common::AMQP::Config.new
      end

      def connection
        @connection ||= Common::AMQP::Connection.new
      end

      def open
        connection.open
      end

      def close
        connection.close
      end

      def logger
        config.logger
      end

    end
  end
end
