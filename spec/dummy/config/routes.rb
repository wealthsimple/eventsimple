Rails.application.routes.draw do
  get 'implicit_user' => 'implicit_user#index'
  get 'custom_user' => 'custom_user#index'
end
