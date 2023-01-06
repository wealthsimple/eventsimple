module Eventable
  class ModelsController < ApplicationController
    def show
      @model_name = params[:name]
    end
  end
end
