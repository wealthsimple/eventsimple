module Eventsimple
  class ModelsController < ApplicationController
    def show
      @model_name = params[:name]
      model_class = event_classes.find { |d| d.name == @model_name }

      scope = apply_filter(model_class, model_class.event_class)

      @latest_entities = scope.last(20).reverse

      check_redirect_to_entity
    end

    private

    def apply_filter(model_class, model_event_class)
      filter_columns = model_class._filter_attributes

      params_filters = params.permit(filters: {})[:filters] || {}
      @filters = filter_columns.to_h { |column| [column, params_filters[column]] }

      return model_event_class unless @filters.any?

      aggregate_class_symbol = model_event_class._aggregate_klass.model_name.element.to_sym
      model_event_class = model_event_class.joins(aggregate_class_symbol)
      @filters.each do |key, value|
        next if value.blank?
        key = model_event_class._aggregate_id if key == :aggregate_id
        model_event_class = model_event_class.where({ aggregate_class_symbol => { key => value } })
      end

      model_event_class
    end

    def check_redirect_to_entity
      return unless @latest_entities.any?

      first_aggregate_id = @latest_entities.first.aggregate_id

      return unless @latest_entities.all? { |entity| entity.aggregate_id == first_aggregate_id }

      redirect_to model_entity_path(@model_name, first_aggregate_id, filters: @filters)
    end
  end
end
