# frozen_string_literal: true

module Eventsimple
  class ReactorWorker
    include Sidekiq::Worker

    def perform(event_global_id, reactor_class)
      event = Retriable.with_context(:reactor) do
        ApplicationRecord.uncached { GlobalID::Locator.locate event_global_id }
      end
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Event #{event_global_id} not found for reactor: #{reactor_class}")
    else
      reactor = reactor_class.constantize
      reactor.new(event).call
    end
  end
end
