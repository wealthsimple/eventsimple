module Eventsimple
  class ModelsController < ApplicationController
    def show
      @model_name = params[:name]
      model_event_class = event_classes.find { |d| d.name == @model_name }.event_class

      model_event_class = apply_filter(model_event_class)

      @latest_entities = model_event_class.last(20).reverse
    end

    private
  
    def apply_filter(model_event_class)
      filter_columns = model_event_class._filter_attributes || []
      return model_event_class unless filter_columns.any?
  
      params_filters = params.permit(filters: {})[:filters] || {}
      @filters = filter_columns.to_h { |column| [column, params_filters[column]] }
  
      return model_event_class unless @filters.any?
  
      aggregate_class_symbol = model_event_class._aggregate_klass.model_name.element.to_sym
      model_event_class = model_event_class.joins(aggregate_class_symbol)
      @filters.each do |key, value|
        next if value.blank?
        model_event_class = model_event_class.where({ aggregate_class_symbol => { key => value } })
      end

      return model_event_class
    end
  end
end
