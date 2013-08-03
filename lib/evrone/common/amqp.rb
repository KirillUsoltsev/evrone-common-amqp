require File.expand_path("../amqp/version", __FILE__)

module Evrone
  module Common
    module AMQP

      autoload :Config,     File.expand_path("../amqp/config",    __FILE__)
      autoload :Session,    File.expand_path("../amqp/session",   __FILE__)
      autoload :Consumer,   File.expand_path("../amqp/consumer",  __FILE__)
      autoload :Message,    File.expand_path("../amqp/message",   __FILE__)
      autoload :Celluloid,  File.expand_path("../amqp/celluloid", __FILE__)
      autoload :Logger,     File.expand_path("../amqp/logger",    __FILE__)

      extend self

      @@config  = Common::AMQP::Config.new
      @@session = Common::AMQP::Session.new

      def configure
        yield config
      end

      def config
        @@config
      end

      def session
        @@session
      end

      def open
        session.open
      end

      def open?
        session.open?
      end

      def close
        session.close
      end

      def logger
        config.logger
      end

      def logger=(val)
        config.logger = val
      end

      def shutdown
        Common::AMQP::Session.shutdown
      end

      def shutdown?
        Common::AMQP::Session.shutdown?
      end

    end
  end
end
