Spree::Core::Engine.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    resources :newsletter, only: [:create] do
      collection do
        post 'delete'
      end
    end
  end
end
