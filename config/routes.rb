Rails.application.routes.draw do
  mount EffectiveMergery::Engine => '/', :as => 'effective_mergery'
end

EffectiveMergery::Engine.routes.draw do
  namespace :admin do
    resources :merges, only: [:new, :create]
  end
end
