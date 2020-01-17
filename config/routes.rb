Rails.application.routes.draw do
  root 'page#index'

  get '/signup', to: 'users#new'
  get '/profile', as: 'profile', to: 'users#show'

  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users, only: [:create]
  resources :progress, only: [:index]

  get '/translation', to: 'translations#edit'
  resources :translations, only: [:create, :update]
  resources :reviews, only: [:create, :index] do
    get 'review', on: :collection
  end
end
