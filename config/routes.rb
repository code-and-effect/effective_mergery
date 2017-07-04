EffectiveMergery::Engine.routes.draw do
  namespace :admin do
    resources :merge, only: [:index, :new, :create] do
      get :attributes, on: :collection
    end
  end
end

Rails.application.routes.draw do
  mount EffectiveMergery::Engine => '/', :as => 'effective_mergery'
end
