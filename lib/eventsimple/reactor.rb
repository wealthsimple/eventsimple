# frozen_string_literal: true

module Eventsimple
  class Reactor < ActiveJob::Base # rubocop:disable Rails/ApplicationJob
    queue_as :eventsimple

    def perform(event)
      call(event)
    end

    around_perform do |job, block|
      event_global_id = job.arguments.first
      reactor_class = job.arguments.second

      # For non database based processors like sidekiq, the reactor may trigger before the
      # transaction is committed. Attempt to wait for the transaction to be commited before
      # running the reactor. This is not a perfect solution, but it's better than nothing.
      if Eventsimple.configuration.retry_reactor_on_record_not_found
        begin
          Retriable.with_context(:reactor) do
            ApplicationRecord.uncached { GlobalID::Locator.locate(event_global_id) }
          end
        rescue ActiveRecord::RecordNotFound
          Rails.logger.error("Event #{event_global_id} not found for reactor: #{reactor_class}")
          return
        end
      end

      block.call
    end
  end
end
