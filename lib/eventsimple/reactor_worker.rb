# frozen_string_literal: true

# legacy worker for backwards compatibility when upgrading from Eventsimple <= 1.0.0
module Eventsimple
  class ReactorWorker
    include Sidekiq::Worker

    def perform(event_global_id, reactor_class)
      gid = GlobalID.parse(event_global_id)

      event = Retriable.with_context(:reactor) do
        gid.model_class.uncached { GlobalID::Locator.locate event_global_id }
      end
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Event #{event_global_id} not found for reactor: #{reactor_class}")
    else
      reactor = reactor_class.constantize
      reactor.new.call(event)
    end
  end
end
