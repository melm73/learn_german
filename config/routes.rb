Rails.application.routes.draw do
  root 'welcome#index'
  resources :users, only: [:index, :new, :create]
end
