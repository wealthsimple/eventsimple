# frozen_string_literal: true

module Eventsimple
  class Configuration
    attr_reader :max_concurrency_retries
    attr_writer :metadata_klass
    attr_writer :parent_record_klass
    attr_accessor :retry_reactor_on_record_not_found

    attr_accessor :ui_visible_models
    attr_reader :queue_priorities

    def initialize
      @dispatchers = []
      @max_concurrency_retries = 2
      @metadata_klass = 'Eventsimple::Metadata'
      @parent_record_klass = 'ApplicationRecord'
      @retry_reactor_on_record_not_found = false

      @ui_visible_models = [] # internal use only
      @queue_priorities = {
        high: :eventsimple_high,
        default: :eventsimple,
        low: :eventsimple_low,
      }
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

    # rubocop:disable Naming/MemoizedInstanceVariableName
    def dispatchers
      @dispatchers_klass_consts ||= @dispatchers.map(&:constantize)
    end

    def metadata_klass
      @metadata_klass_const ||= @metadata_klass.constantize
    end

    def parent_record_klass
      @parent_record_const ||= @parent_record_klass.constantize
    end
    # rubocop:enable Naming/MemoizedInstanceVariableName

    def queue_priorities=(priorities)
      raise ArgumentError, 'queue_priorities must be a hash' unless priorities.is_a?(Hash)
      raise ArgumentError, 'queue_priorities must include :default priority' unless priorities.key?(:default)

      @queue_priorities = priorities
    end
  end
end
