Rails.application.routes.draw do
  mount Eventable::Engine => "/eventable"
end
