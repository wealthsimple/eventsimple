module Eventable
  module Entity
    def event_driven_by(event_klass, aggregate_id: :canonical_id)
      has_many :events, class_name: event_klass.name.to_s,
        foreign_key: :aggregate_id,
        primary_key: aggregate_id,
        dependent: :delete_all,
        inverse_of: model_name.element.to_sym,
        autosave: false,
        validate: false

      class_attribute :ignored_for_projection, default: []

      # disable automatic timestamp updates
      self.record_timestamps = false


      include InstanceMethods
      extend ClassMethods
    end

    module InstanceMethods
      def projection_matches_events?
        reprojected = self.class.find(id).reproject

        attributes == reprojected.attributes
      end

      def reproject(at: nil)
        default_ignore_props = %w[id lock_version]

        event_history = at ? events.where('created_at <= ?', at).load : events.load
        ignore_props = default_ignore_props.concat(ignored_for_projection).map(&:to_s)
        assign_attributes(self.class.column_defaults.except(*ignore_props))

        event_history.each do |event|
          event.apply(self)
          event.apply_timestamps(self)
        end

        self
      end
    end

    module ClassMethods
      def event_class
        self.reflect_on_all_associations(:has_many).find { |association|
          association.name == :events
        }.klass
      end
    end
  end
end
