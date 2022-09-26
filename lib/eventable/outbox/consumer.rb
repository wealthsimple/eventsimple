# frozen_string_literal: true

require 'eventable/outbox/models/cursor'

module Eventable
  module Outbox
    module Consumer
      def self.extended(klass)
        klass.class_exec do
          class_attribute :_event_klass
          class_attribute :_processor_klass
          class_attribute :stop_consumer, default: false

          Signal.trap('SIGINT') do
            self.stop_consumer = true
            STDOUT.puts('SIGINT received, stopping consumer')
          end
        end
      end

      def consumes_event(event_klass, concurrency: 1)
        event_klass._outbox_mode = true
        event_klass._outbox_concurrency = concurrency

        self._event_klass = event_klass
      end

      def processor(processor_klass)
        self._processor_klass = processor_klass
      end

      def start # rubocop:disable Metrics/AbcSize
        cursor = Outbox::Cursor.fetch(_event_klass, 0)

        until stop_consumer
          _event_klass.unscoped.in_batches(start: cursor + 1, load: true).each do |batch|
            batch.each { |event| _processor_klass.new(event).call }
            cursor = batch.last.id
            Outbox::Cursor.set(_event_klass, 0, cursor)

            break if stop_consumer
          end

          sleep(1)
        end
      end
    end
  end
end
