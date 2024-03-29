# frozen_string_literal: true

module Eventsimple
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
        return event_klass::Message.new(decoded) if event_klass.const_defined?(:Message)

        decoded
      when Hash
        return event_klass::Message.new(value) if event_klass.const_defined?(:Message)

        value
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
      return event_klass::Message.new(decoded) if event_klass.const_defined?(:Message)

      decoded
    end
  end
end
