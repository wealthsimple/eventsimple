module Eventable
  class InvalidTransition < StandardError
    attr_reader :klass

    def initialize(klass = nil)
      @klass = klass
      super
    end

    def to_s
      "Invalid State Transition for #{klass}"
    end
  end
end
