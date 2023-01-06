module Eventable
  class EntitiesController < ApplicationController
    def show
      @model_name = params[:model_name]
      @canonical_id = params[:id]
      @event_id = params[:e]

      @entity = EventModelResolver.get_entity(model_name: @model_name, canonical_id: @canonical_id)

      # Event History
      @entity_event_history = EventModelResolver.get_entity_history(
        model_name: @model_name,
        canonical_id: @canonical_id,
      )
      @latest_event = @entity_event_history.first
      @selected_event = @entity_event_history.find { |e| e.id == @event_id.to_i }
      if @selected_event.nil?
        @selected_event = @latest_event
        @entity_delta = {}
      else
        @entity.reproject(at: @selected_event.created_at)
        @entity_delta = @entity.changes
      end
      @is_historical = @selected_event.id != @latest_event.id
    rescue StandardError => e
      @error_message = e.message
    end
  end
end
