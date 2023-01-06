Eventable::Engine.routes.draw do
  root to: 'home#index'
  resources :models, only: :show, param: :name do
    resources :entities, only: :show
  end
end
