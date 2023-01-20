module Eventable
  class ModelsController < ApplicationController
    def show
      @model_name = params[:name]

      model_event_class = event_classes.find { |d| d.name == @model_name }.event_class
      @latest_entities = model_event_class.last(20).reverse
    end

    def search
      entity_id = params.require(:search).permit(:entity_id)[:entity_id]
      redirect_to helpers.model_entity_path(params[:name], entity_id)
    end
  end
end
