module Eventable
  class ModelsController < ApplicationController
    def show
      @model_name = params[:name]

      @latest_entities = helpers.get_lastest_entities!(model_name: @model_name)
    end

    def search
      entity_id = params.require(:search).permit(:entity_id)[:entity_id]
      redirect_to helpers.model_entity_path(params[:name], entity_id)
    end
  end
end
