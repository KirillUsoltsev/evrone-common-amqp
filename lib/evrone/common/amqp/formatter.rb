require 'json'
require 'stringio'

module Evrone
  module Common
    module AMQP

      class Formatter

        @@formats = {}

        class Format

          attr_reader :content_type

          def initialize(content_type)
            @content_type = content_type
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

          def define(content_type, &block)
            fmt = Format.new content_type
            fmt.instance_eval(&block)
            formats.merge! content_type => fmt
          end

          def lookup(content_type)
            formats[content_type]
          end

          def pack(content_type, body)
            if fmt = lookup(content_type)
              fmt.pack.call(body)
            end
          end

          def unpack(content_type, model, body)
            if fmt = lookup(content_type)
              fmt.unpack.call(body, model)
            end
          end

        end

        define 'text/plain' do

          pack do |body|
            body.to_s
          end

          unpack do |body, _|
            body
          end
        end

        define 'application/json' do

          pack do |body|
            body.to_json
          end

          unpack do |payload, model|
            if model && model.respond_to?(:from_json)
              model.from_json payload
            else
              JSON.parse(payload)
            end
          end
        end

        define 'application/x-protobuf' do

          pack do |object|
            object.encode.to_s
          end

          unpack do |payload, model|
            raise ModelDoesNotExists unless model
            model.decode payload
          end

          class ModelDoesNotExists < Exception ; end
        end
      end

    end
  end
end
