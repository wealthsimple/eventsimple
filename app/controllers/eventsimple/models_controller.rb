module Eventsimple
  class ModelsController < ApplicationController
    def show
      @model_name = params[:name]
      @metadata = params.permit(metadata: {})[:metadata]

      @metadata_attributes = Eventsimple.configuration.metadata_klass.attribute_names

      model_event_class = event_classes.find { |d| d.name == @model_name }.event_class

      if @metadata&.present?
        @metadata.each do |key, value|
          next if value.blank?
          model_event_class = model_event_class.where("metadata->>? = ?", key, value)
        end
      else
        @metadata = {}
      end

      @latest_entities = model_event_class.last(20).reverse
    end
  end
end
