require File.expand_path("../amqp/version", __FILE__)

module Evrone
  module Common
    module AMQP
      autoload :Config,     File.expand_path("../amqp/config",     __FILE__)
      autoload :Session,    File.expand_path("../amqp/session",    __FILE__)
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

      def session
        @session ||= Common::AMQP::Session.new
      end

      def open
        session.open
      end

      def close
        session.close
      end

      def logger
        config.logger
      end

    end
  end
end
