require 'json'
require 'stringio'

module Evrone
  module Common
    module AMQP

      class Formatter

        @@formats = {}

        class Format

          attr_reader :name

          def initialize(name)
            @name = name
          end

          def content_type(val = nil)
            @content_type = val if val
            @content_type
          end

          def pack(&block)
            @pack = block if block_given?
            @pack
          end

          def unpack(&block)
            @unpack = block if block_given?
            @unpack
          end

        end

        class << self

          def formats
            @@formats
          end

          def define(name, &block)
            fmt = Format.new name
            fmt.instance_eval(&block)
            formats.merge! name => fmt
          end

          def lookup(name)
            formats[name]
          end

          def lookup_by_content_type(content_type)
            if found = formats.find{|k,v| v.content_type == content_type }
              found.last
            end
          end

          def content_type(name)
            formats[name] && formats[name].content_type
          end

          def pack(content_type, consumer, body)
            if fmt = lookup_by_content_type(content_type)
              fmt.pack.call(body, consumer)
            end
          end

          def unpack(content_type, consumer, body)
            if fmt = lookup_by_content_type(content_type)
              fmt.unpack.call(body, consumer)
            end
          end

        end

        define :string do

          content_type 'text/plain'

          pack do |body, _|
            body.to_s
          end

          unpack do |body, _|
            body
          end
        end

        define :json do

          content_type 'application/json'

          pack do |body, _|
            body.to_json
          end

          unpack do |payload, consumer|
            if m = consumer.class.model && m.respond_to?(:from_json)
              m.from_json payload
            else
              JSON.parse(payload)
            end
          end
        end

        define :ruby_protocol_buffers do

          content_type 'application/x-protobuf'

          pack do |body, _|
            StringIO.open do |io|
              body.serialize(io)
              io.rewind
              io.read
            end
          end

          unpack do |payload, consumer|
            m = consumer.class.model
            m.parse payload
          end
        end

      end

    end
  end
end
