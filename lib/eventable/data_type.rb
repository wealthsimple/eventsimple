# frozen_string_literal: true

module Eventable
  class DataType < ActiveModel::Type::Value
    def initialize(event_klass)
      @event_klass = event_klass
      super()
    end

    attr_reader :event_klass

    def type
      :data_type
    end

    def cast_value(value)
      case value
      when String
        decoded = ActiveSupport::JSON.decode(value)
        return decoded if decoded.empty?

        event_klass::Message.new(decoded)
      when Hash
        event_klass::Message.new(value)
      when event_klass::Message
        value
      end
    end

    def serialize(value)
      case value
      when Hash, event_klass::Message
        ActiveSupport::JSON.encode(value)
      else
        super
      end
    end

    def deserialize(value)
      decoded = ActiveSupport::JSON.decode(value)
      return decoded if decoded.empty?

      event_klass::Message.new(decoded)
    end
  end
end
