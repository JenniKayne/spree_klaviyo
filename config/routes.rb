Spree::Core::Engine.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    resources :newsletter, only: [:create]
  end
end
