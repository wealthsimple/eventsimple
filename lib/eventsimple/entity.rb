# frozen_string_literal: true

module Eventsimple
  module Entity
    DEFAULT_IGNORE_PROPS = %w[id lock_version].freeze

    def event_driven_by(event_klass, aggregate_id:, filter_attributes: [])
      begin
        if table_exists? && !column_names.include?(locking_column)
          raise ArgumentError, "A #{locking_column} column is required to enable optimistic locking"
        end

        if defined?(event_klass._aggregate_id) && event_klass.table_exists? && table_exists?
          raise ArgumentError, "aggregate_id mismatch event:#{event_klass._aggregate_id} entity:#{aggregate_id}" if aggregate_id != event_klass._aggregate_id

          aggregate_column_type_in_event = event_klass.column_for_attribute(:aggregate_id).type
          aggregate_column_type_in_entity = column_for_attribute(aggregate_id).type

          raise ArgumentError, "column type mismatch - event:#{aggregate_column_type_in_event} entity:#{aggregate_column_type_in_entity}" if aggregate_column_type_in_event != aggregate_column_type_in_entity
        end
      rescue ActiveRecord::NoDatabaseError
        # skip checks if the database is not yet created
      end

      has_many :events, class_name: event_klass.name.to_s,
        foreign_key: :aggregate_id,
        primary_key: aggregate_id,
        dependent: :delete_all,
        inverse_of: model_name.element.to_sym,
        autosave: false,
        validate: false

      after_initialize :readonly!

      class_attribute :ignored_for_projection, default: []

      class_attribute :_filter_attributes
      self._filter_attributes = [aggregate_id] | Array.wrap(filter_attributes)

      class_attribute :_aggregate_id
      self._aggregate_id = aggregate_id

      # disable automatic timestamp updates
      self.record_timestamps = false

      Eventsimple.configuration.ui_visible_models |= [self]

      include InstanceMethods
      extend ClassMethods
    end

    module InstanceMethods
      def projection_matches_events?
        reprojected = self.class.find(id).reproject

        attributes == reprojected.attributes
      end

      def enable_writes!(&block)
        was_readonly = @readonly
        @readonly = false

        return unless block

        yield self
        @readonly = was_readonly
      end

      def reproject(at: nil)
        event_history = at ? events.where('created_at <= ?', at).load : events.load
        ignore_props = (DEFAULT_IGNORE_PROPS + ignored_for_projection).map(&:to_s)
        assign_attributes(self.class.column_defaults.except(*ignore_props))

        event_history.each do |event|
          event.apply_timestamps(self)
          event.apply(self)
        end

        self
      end
    end

    module ClassMethods
      def event_class
        reflect_on_all_associations(:has_many).find { |association|
          association.name == :events
        }.klass
      end
    end
  end
end
