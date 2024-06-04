# frozen_string_literal: true

require 'with_advisory_lock'
require 'eventsimple/outbox/models/cursor'

module Eventsimple
  module Outbox
    module Consumer
      class ExitError < StandardError; end

      def self.extended(klass)
        klass.class_exec do
          class_attribute :_event_klass
          class_attribute :_identifier
          class_attribute :_processor_klass
          class_attribute :_processor_pool
          class_attribute :_concurrency, default: 5
          class_attribute :_batch_size, default: 1000
          class_attribute :stop_consumer, default: false
        end
      end

      def identifier(name)
        self._identifier = name
      end

      def consumes_event(event_klass)
        self._event_klass = event_klass
      end

      def processor(processor_klass, concurrency: 5)
        self._concurrency = concurrency
        self._processor_klass = processor_klass
        self._processor_pool = _concurrency.times.map { processor_klass.new }
      end

      def start # rubocop:disable Metrics/AbcSize
        Signal.trap('INT') do
          self.stop_consumer = true
          $stdout.puts('INT received, stopping consumer')
        end
        Signal.trap('TERM') do
          self.stop_consumer = true
          $stdout.puts('TERM received, stopping consumer')
        end

        run_consumer
      end

      def run_consumer
        raise 'Eventsimple: No event class defined' unless _event_klass
        raise 'Eventsimple: No processor defined' unless _processor_klass
        raise 'Eventsimple: No identifier defined' unless _identifier
        raise 'Eventsimple: No concurrency defined' unless _concurrency.is_a?(Integer)

        $stdout.puts("Starting consumer for #{_identifier}")

        cursor = Outbox::Cursor.fetch(_identifier)

        until stop_consumer
          _event_klass.unscoped.in_batches(start: cursor + 1, load: true, of: _batch_size).each do |batch|
            grouped_events = batch.group_by { |event| event.aggregate_id.unpack1('L') % _concurrency }

            promises = grouped_events.map { |index, events|
              Concurrent::Promises.future {
                events.each do |event|
                  _processor_pool[index].call(event)
                  raise ExitError if stop_consumer
                end
              }
            }

            Concurrent::Promises.zip(*promises).value!

            cursor = batch.last.id
            Outbox::Cursor.set(_identifier, cursor)
          end

          sleep(1)
        end
      rescue ExitError
        $stdout.puts("Stopping consumer for #{_identifier}")
      end
    end
  end
end
