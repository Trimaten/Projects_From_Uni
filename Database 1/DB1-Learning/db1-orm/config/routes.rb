Rails.application.routes.draw do
  get '/up', to: proc { [200, {}, ['OK']] }
  
  resources :matches, only: [:create, :show] do
    collection do
      post 'join'
      post 'play'
    end
    member do
      get 'leaderboard'
    end
  end

  resources :questions, only: [:create]
  resources :question_pools, only: [:index, :create, :show]
end