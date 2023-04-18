module Eventsimple
  class ModelsController < ApplicationController
    def show
      @model_name = params[:name]

      model_event_class = event_classes.find { |d| d.name == @model_name }.event_class
      @latest_entities = model_event_class.last(20).reverse
    end
  end
end
