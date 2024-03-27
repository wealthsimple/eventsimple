module Eventsimple
  class InvalidTransition < StandardError
    attr_reader :klass, :aggregate_id

    def initialize(klass = nil, aggregate_id = nil)
      @klass = klass
      @aggregate_id = aggregate_id
      super(klass)
    end

    def to_s
      "Invalid State Transition for #{klass} on aggregate_id: #{aggregate_id}"
    end
  end
end
