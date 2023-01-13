Eventable::Engine.routes.draw do
  root to: 'home#index'

  resources :models, only: [:show], param: :name do
    member do
      post :search
    end

    resources :entities, only: :show
  end

  get '/auth', to: 'auth#redirect'
  get '/auth/callback', to: 'auth#callback'

end
