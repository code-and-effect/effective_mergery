Rails.application.routes.draw do
  mount EffectiveMergery::Engine => '/', :as => 'effective_mergery'
end

EffectiveMergery::Engine.routes.draw do
  namespace :admin do
    resources :merges, only: [:index, :new, :create] do
      get :attributes, on: :collection
    end
  end
end
