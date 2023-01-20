module Eventable
  class EntitiesController < ApplicationController
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    def show
      @model_name = params[:model_name]
      @model_class = event_classes.find { |d| d.name == @model_name }
      @canonical_id = params[:id]
      @event_id = params[:e] || -1
      @tab_id = params[:t] == 'event' ? 'event' : 'entity'

      @entity = @model_class.find_by!(canonical_id: @canonical_id)
      @entity_event_history = @entity.events.reverse

      @selected_event = @entity_event_history.find { |e|
        e.id == @event_id.to_i
      } || @entity_event_history.first

      previous_index = @entity_event_history.find_index { |e| e.id == @selected_event.id } + 1
      @previous_event = @entity_event_history[previous_index]

      @entity_changes = changes
    rescue StandardError => e
      @error_message = e.message
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity

    private

    def changes
      current_attributes.map do |attr_name, *|
        {
          label: attr_name,
          current_value: current_attributes[attr_name],
          historical_value: previous_attributes[attr_name],
          is_changed: current_attributes[attr_name] != previous_attributes[attr_name],
        }
      end
    end

    def current_attributes
      @current_attributes ||= @entity.reproject(at: @selected_event.created_at).attributes.except(
        'lock_version',
      )
    end

    def previous_attributes
      @previous_attributes ||=
        if @previous_event
          @entity.reproject(at: @previous_event.created_at).attributes.except(
            'lock_version',
          )
        else
          @model_class.column_defaults
        end
    end
  end
end
