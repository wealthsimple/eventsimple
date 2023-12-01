module Eventsimple
  class ModelsController < ApplicationController
    def show
      @model_name = params[:name]
      model_event_class = event_classes.find { |d| d.name == @model_name }.event_class

      if model_event_class.eventsimple_search_columns.present?
        filter_columns = model_event_class.eventsimple_search_columns # {status:}
        params_filters = params.permit(filters: {})[:filters] || {}

        @filters = filter_columns.to_h { |column| [column, params_filters[column]] }
        
        if @filters.present?
          aggregate_class = model_event_class._aggregate_klass.model_name.element.to_sym
          @filters.each do |key, value|
            debugger
            next if value.blank?
            model_event_class = model_event_class.joins(aggregate_class).where({aggregate_class => {key => value}})
          end
        end
      end

      @latest_entities = model_event_class.last(20).reverse
    end
  end
end
