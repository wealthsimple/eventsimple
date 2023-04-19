# frozen_string_literal: true

module Eventable
  class ReactorWorker
    include Sidekiq::Worker

    def perform(event_global_id, reactor_class)
      event = Retriable.retriable(
        on: ActiveRecord::RecordNotFound,
        tries: 7, base_interval: 1.0, multiplier: 1.0, rand_factor: 0.0
      ) do
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
