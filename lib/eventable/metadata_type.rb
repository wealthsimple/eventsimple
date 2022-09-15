# frozen_string_literal: true

module Eventable
  class MetadataType < ActiveModel::Type::Value
    def type
      :metadata_type
    end

    def cast_value(value)
      case value
      when String
        decoded = ActiveSupport::JSON.decode(value)
        return decoded if decoded.empty?

        Metadata.new(decoded)
      when Hash
        Metadata.new(value)
      when Metadata
        value
      end
    end

    def serialize(value)
      case value
      when Hash, Metadata
        ActiveSupport::JSON.encode(value)
      else
        super
      end
    end

    def deserialize(value)
      decoded = ActiveSupport::JSON.decode(value)

      Metadata.new(decoded)
    end
  end
end
