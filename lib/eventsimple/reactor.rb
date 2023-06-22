# frozen_string_literal: true

module Eventsimple
  class Reactor < ActiveJob::Base # rubocop:disable Rails/ApplicationJob
    queue_as :eventsimple

    discard_on ActiveJob::DeserializationError do |job, error|
      Rails.logger.warn("Event #{job.arguments.first} not found for reactor: #{self.class}")
    end

    def perform(event)
      call(event)
    end
  end
end
