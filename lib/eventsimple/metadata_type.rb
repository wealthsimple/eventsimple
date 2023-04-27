# frozen_string_literal: true

module Eventsimple
  class MetadataType < ActiveModel::Type::Value
    def type
      :metadata_type
    end

    def cast_value(value)
      case value
      when String
        decoded = ActiveSupport::JSON.decode(value)
        return decoded if decoded.empty?

        Eventsimple.configuration.metadata_klass.new(decoded)
      when Hash
        Eventsimple.configuration.metadata_klass.new(value)
      when Eventsimple.configuration.metadata_klass
        value
      end
    end

    def serialize(value)
      case value
      when Hash, Eventsimple.configuration.metadata_klass
        ActiveSupport::JSON.encode(value)
      else
        super
      end
    end

    def deserialize(value)
      decoded = ActiveSupport::JSON.decode(value)

      Eventsimple.configuration.metadata_klass.new(decoded)
    end
  end
end
