# frozen_string_literal: true

# Dispatcher implementation.
module Eventable
  class EventDispatcher
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
    def self.on(*events, sync: [], async: [])
      rules.register(events: events.flatten, sync: Array(sync), async: Array(async))
    end

    # Dispatches events to matching Reactors once.
    # Called by all events after they are created.
    def self.dispatch(event)
      reactors = rules.for(event)
      reactors.sync.each do |reactor|
        reactor.new(event).call
        event.reload
      end
      reactors.async.each do |reactor|
        ReactorWorker.perform_async(event.to_global_id.to_s, reactor.to_s)
      end
    end

    def self.rules
      @rules ||= RuleSet.new
    end

    class RuleSet
      def initialize
        @rules = Hash.new { |h, k| h[k] = ReactorSet.new }
      end

      # Register events with their sync and async Reactors
      def register(events:, sync:, async:)
        events.each do |event|
          @rules[event].add_sync sync
          @rules[event].add_async async
        end
      end

      # Return a ReactorSet containing all Reactors matching an Event
      def for(event)
        reactors = ReactorSet.new

        @rules.each do |event_class, rule|
          # Match event by class including ancestors. e.g. All events match a role for BaseEvent.
          if event.is_a?(event_class)
            reactors.add_sync rule.sync
            reactors.add_async rule.async
          end
        end

        reactors
      end
    end

    # Contains sync and async reactors. Used to:
    # * store reactors via Rules#register
    # * return a set of matching reactors with Rules#for
    class ReactorSet
      attr_reader :sync, :async

      def initialize
        @sync = Set.new
        @async = Set.new
      end

      def add_sync(reactors)
        @sync += reactors
      end

      def add_async(reactors)
        @async += reactors
      end
    end
  end
end
