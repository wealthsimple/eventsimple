module Eventable
  class EntitiesController < ApplicationController
    def show
      @model_name = params[:model_name]
      @canonical_id = params[:id]
      @event_id = params[:e] || -1

      # Event History
      @entity_event_history = helpers.get_entity_history!(
        model_name: @model_name,
        canonical_id: @canonical_id,
      )

      @entity = helpers.get_entity!(model_name: @model_name, canonical_id: @canonical_id)

      @latest_event = @entity_event_history.first
      @selected_event = @entity_event_history.find { |e| e.id == @event_id.to_i } || @latest_event

      @is_historical = @selected_event.id != @latest_event.id
      entity_at = @is_historical ? @selected_event.created_at : nil

      @entity_properties = helpers.get_entity_properties!(model_name: @model_name, canonical_id: @canonical_id, at: entity_at)
    rescue StandardError => e
      @error_message = e.message
    end
  end
end
