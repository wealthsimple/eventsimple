module Eventable
    class EventModelResolver

      def self.resolve_model_class(model_name)
        model_name.constantize
      rescue StandardError
        raise "Event source model could not be resolved for '#{model_name}'."
      end

      def self.resolve_event_class(model_name)
        model_class = resolve_model_class(model_name)
        model_class.reflect_on_all_associations(:has_many).find { |r|
          r.name == :events
        }.class_name.constantize
      rescue StandardError => e
        raise "Event source model event could not be resolved for '#{model_name}'."
      end

      def self.get_entity(model_name:, canonical_id:)
        model_class = resolve_model_class(model_name)
        model_class.find_by!(canonical_id: canonical_id)
      rescue StandardError
        raise "Event source entity could not be found for the model '#{model_name}' and canonical identifier '#{canonical_id}'."
      end

      def self.get_entity_history(model_name:, canonical_id:)
        entity = get_entity(model_name: model_name, canonical_id: canonical_id)
        entity.events.reverse
      end
    end
end

