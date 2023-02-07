# frozen_string_literal: true

module Eventable
  class Configuration
    attr_reader :max_concurrency_retries

    def initialize
      @max_concurrency_retries = 2
    end

    def max_concurrency_retries=(value)
      unless value.is_a?(Integer) && value.positive?
        raise ArgumentError, 'max_concurrency_retries must be a positive integer'
      end

      @max_concurrency_retries = value
    end
  end
end
