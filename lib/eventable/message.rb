# frozen_string_literal: true

module Eventable
  class Message < Dry::Struct
    transform_keys(&:to_sym)

    # dry types will apply default values only on missing keys
    # modify the behaviour so defaults are used on nil values as well
    transform_types do |type|
      if type.default?
        type.constructor do |value|
          value.nil? ? Dry::Types::Undefined : value
        end
      else
        type
      end
    end
  end
end
