module Eventsimple
  class Dispatcher
    def self.on(*events, sync: [], async: [])
      # Register Reactors to Events.
      # * Reactors registered with `sync` will be synced synchronously
      # * Reactors registered with `async` will be synced asynchronously via a Sidekiq Job
      #
      # Example:
      #
      #   on BaseEvent, sync: LogEvent, async: TrackEvent
      #   on PledgeCancelled, PaymentFailed, async: [NotifyAdmin, CreateTask]
      #   on [PledgeCancelled, PaymentFailed], async: [NotifyAdmin, CreateTask]
      #
      EventDispatcher.rules.register(events: events.flatten, sync: Array(sync), async: Array(async))
    end
  end
end
