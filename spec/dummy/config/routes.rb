# frozen_string_literal: true

Rails.application.routes.draw do
  mount Eventsimple::Engine => "/eventsimple"
end
