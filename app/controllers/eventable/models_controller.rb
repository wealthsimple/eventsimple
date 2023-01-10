module Eventable
  class ModelsController < ApplicationController
    include Eventable::EventModelResolver

    def show
      @model_name = params[:name]

      @latest_entities = get_lastest_entities!(model_name: @model_name)
    end
  end
end
