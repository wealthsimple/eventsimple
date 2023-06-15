# frozen_string_literal: true

# Copyright (c) 2017 Kickstarter, PBC

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Dispatcher implementation.
module Eventsimple
  class EventDispatcher
    # Dispatches events to matching Reactors once.
    # Called by all events after they are created.
    def self.dispatch(event)
      reactors = rules.for(event)
      reactors.sync.each do |reactor|
        reactor.perform_now(event)
        event.reload
      end
      reactors.async.each do |reactor|
        reactor.perform_later(event)
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
