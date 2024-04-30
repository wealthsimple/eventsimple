# frozen_string_literal: true

require 'with_advisory_lock'
require 'eventsimple/outbox/models/cursor'

module Eventsimple
  module Outbox
    module Consumer
      def self.extended(klass)
        klass.class_exec do
          class_attribute :_event_klass
          class_attribute :_processor_klass
          class_attribute :_processor
          class_attribute :stop_consumer, default: false
          class_attribute :_identifier
        end
      end

      def identifier(name)
        self._identifier = name
      end

      def consumes_event(event_klass, group_size: 1)
        event_klass._outbox_enabled = true
        event_klass._consumer_group_size = group_size

        self._event_klass = event_klass
      end

      def processor(processor_klass)
        self._processor_klass = processor_klass
        self._processor = processor_klass.new
      end

      def start(group_number: 0) # rubocop:disable Metrics/AbcSize
        Signal.trap('INT') do
          self.stop_consumer = true
          $stdout.puts('INT received, stopping consumer')
        end
        Signal.trap('TERM') do
          self.stop_consumer = true
          $stdout.puts('TERM received, stopping consumer')
        end

        run_consumer(group_number: group_number)
      end

      def run_consumer(group_number:)
        raise 'Eventsimple: No event class defined' unless _event_klass
        raise 'Eventsimple: No processor defined' unless _processor
        raise 'Eventsimple: No identifier defined' unless _identifier

        Rails.logger.info("Starting consumer for #{_identifier}, processing #{_event_klass} events with group number #{group_number}")

        cursor = Outbox::Cursor.fetch(_identifier, group_number: group_number)

        until stop_consumer
          _event_klass.unscoped.in_batches(start: cursor + 1, load: true).each do |batch|
            batch.each do |event|
              _processor.call(event)

              cursor = event.id
              break if stop_consumer
            end

            Outbox::Cursor.set(_identifier, cursor, group_number: group_number)
            break if stop_consumer
          end

          sleep(1)
        end
      end
    end
  end
end
