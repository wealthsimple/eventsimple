module Eventsimple
  module Entity
    DEFAULT_IGNORE_PROPS = %w[id lock_version].freeze

    def event_driven_by(event_klass, aggregate_id:, filter_attributes: [])
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
        @readonly = false

        if block
          yield
          @readonly = true
        end
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
