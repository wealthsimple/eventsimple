module Eventable
  module ApplicationHelper
    def resolve_model_class!(model_name)
      model_name.constantize
    rescue StandardError
      raise "Event source model could not be resolved for '#{model_name}'."
    end

    def get_entity!(model_name:, canonical_id:)
      model_class = resolve_model_class!(model_name)
      model_class.find_by!(canonical_id: canonical_id)
    rescue StandardError
      raise "Event source entity could not be found for the model " \
            "'#{model_name}' and canonical identifier '#{canonical_id}'."
    end

    # rubocop:disable Metrics/AbcSize
    def get_entity_properties!(model_name:, canonical_id:, at: nil)
      entity = get_entity!(model_name: model_name, canonical_id: canonical_id)

      changes = {}
      result = []
      if at.present?
        entity.reproject(at: at)
        changes = entity.changes
      end

      entity.attributes.each do |attr_name, attr_value|
        current_value = attr_value
        historical_value = attr_value
        if at.present? && changes.key?(attr_name.to_s)
          current_value = changes[attr_name.to_s][0]
          historical_value = changes[attr_name.to_s][1]
        end
        result.push({
          label: attr_name,
          current_value: current_value,
          historical_value: historical_value,
          is_changed: current_value != historical_value,
        })
      end
      result
    rescue StandardError
      raise "Event source entity could not be found for the model " \
            "'#{model_name}' and canonical identifier '#{canonical_id}'."
    end
    # rubocop:enable Metrics/AbcSize

    def get_entity_history!(model_name:, canonical_id:)
      entity = get_entity!(model_name: model_name, canonical_id: canonical_id)
      entity.events.reverse
    end
  end
end
