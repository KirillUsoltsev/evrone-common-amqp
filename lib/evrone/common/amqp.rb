require File.expand_path("../amqp/version", __FILE__)

module Evrone
  module Common
    module AMQP

      autoload :Config,     File.expand_path("../amqp/config",    __FILE__)
      autoload :Session,    File.expand_path("../amqp/session",   __FILE__)
      autoload :Consumer,   File.expand_path("../amqp/consumer",  __FILE__)
      autoload :CLI,        File.expand_path("../amqp/cli",       __FILE__)
      autoload :Formatter,  File.expand_path("../amqp/formatter", __FILE__)

      module Supervisor
        autoload :Threaded, File.expand_path("../amqp/supervisor/threaded", __FILE__)
      end

      autoload :Logger,         File.expand_path("../amqp/mixins/logger",          __FILE__)
      autoload :Callbacks,      File.expand_path("../amqp/mixins/callbacks",       __FILE__)

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
        Evrone::Common::AMQP::Supervisor::Threaded.shutdown
      end

      def shutdown?
        Common::AMQP::Session.shutdown?
      end

    end
  end
end
