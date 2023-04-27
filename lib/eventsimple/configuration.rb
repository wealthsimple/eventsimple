# frozen_string_literal: true

module Eventsimple
  class Configuration
    attr_reader :max_concurrency_retries, :dispatchers
    attr_writer :metadata_class

    attr_accessor :ui_visible_models

    def initialize
      @max_concurrency_retries = 2
      @dispatchers = []

      # internal use only
      @ui_visible_models = []
      @metadata_klass = 'Metadata'
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

    def metadata_klass
      @klass ||= @metadata_klass.constantize
    end
  end
end
