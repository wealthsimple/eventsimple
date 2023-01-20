module Eventable
  class EntitiesController < ApplicationController
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def show
      @model_name = params[:model_name]
      model_class = event_classes.find { |d| d.name == @model_name }
      @canonical_id = params[:id]
      @event_id = params[:e] || -1
      @tab_id = params[:t] == 'event' ? 'event' : 'entity'

      @entity = model_class.find_by!(canonical_id: @canonical_id)

      @entity_event_history = @entity.events.reverse

      @latest_event = @entity_event_history.first
      @selected_event = @entity_event_history.find { |e| e.id == @event_id.to_i } || @latest_event

      @is_historical = @selected_event.id != @latest_event.id
      entity_at = @is_historical ? @selected_event.created_at : nil

      @entity_properties = entity_properties!(entity: @entity, at: entity_at)
    rescue StandardError => e
      @error_message = e.message
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

    private

    # rubocop:disable Metrics/AbcSize
    def entity_properties!(entity:, at: nil)
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
    end
    # rubocop:enable Metrics/AbcSize
  end
end
