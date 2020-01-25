Rails.application.routes.draw do
  root 'page#index'

  get '/signup', to: 'users#new'

  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'

  resources :users, only: [:create] do
    get 'current_user_profile', on: :collection
  end

  resources :words, only: [:index]
  resources :progress, only: [:index]

  get '/translation', to: 'translations#edit'
  resources :translations, only: [:create, :update, :index]
  resources :reviews, only: [:create, :index]
end
