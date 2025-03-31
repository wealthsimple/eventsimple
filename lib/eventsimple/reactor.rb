# frozen_string_literal: true

module Eventsimple
  class Reactor < ActiveJob::Base # rubocop:disable Rails/ApplicationJob
    class_attribute :priority_queue, default: :default

    def self.queue_priority(priority)
      raise ArgumentError, "Invalid queue priority: #{priority}" unless Eventsimple.configuration.queue_priorities.key?(priority)
      self.priority_queue = priority
    end

    def self.queue_as(*args)
      raise ArgumentError, "queue_as is not supported in Eventsimple::Reactor. Use queue_priority instead."
    end

    def queue_name
      Eventsimple.configuration.queue_priorities[priority_queue]
    end

    discard_on ActiveJob::DeserializationError do |job, error|
      Rails.logger.warn("Event #{job.arguments.first} not found for reactor: #{self.class}")
    end

    def perform(event)
      call(event)
    end
  end
end
