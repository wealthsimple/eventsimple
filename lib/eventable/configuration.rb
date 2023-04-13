# frozen_string_literal: true

module Eventable
  class Configuration
    attr_reader :max_concurrency_retries, :dispatchers
    attr_accessor :ui_visible_models

    def initialize
      @max_concurrency_retries = 2
      @dispatchers = []
      @ui_visible_models = [] # internal use only
    end

    def max_concurrency_retries=(value)
      unless value.is_a?(Integer) && value.positive?
        raise ArgumentError, 'max_concurrency_retries must be a positive integer'
      end

      @max_concurrency_retries = value
    end

    def dispatchers=(value)
      raise ArgumentError, 'dispatchers must be an array' unless value.is_a?(Array)

      @dispatchers = value
    end
  end
end
