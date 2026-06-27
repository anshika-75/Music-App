# Define the URL routing rules for the application.
Rails.application.routes.draw do
  # Health check endpoint for uptime monitoring and deployment verification
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the default homepage (pointing to the Login form)
  root "sessions#new"
#session - controller , index -> action
  # User signup and account deletion routes (handled by UsersController)
  resources :users, only: [:new, :create, :destroy]

  # Namespace for Artist actions. Prefixes URL paths with '/artist' 
  # and maps them to controllers in the 'Artist::' module.
  namespace :artist do
    resources :songs                                # Artist dashboard and Song CRUD (new, create, show, edit, update, destroy)
    resources :profiles, only: [:edit, :update]    # Artist profile metadata edits
  end

  # Namespace for Listener actions. Prefixes URL paths with '/listener'
  # and maps them to controllers in the 'Listener::' module.
  namespace :listener do
    resources :profiles, only: [:edit, :update]    # Listener profile edits & avatar photo uploads
    get "/search", to: "searches#index", as: :search                # Initial search dashboard view
    get "/search/results", to: "searches#results", as: :search_results  # Search query results page
  end

  # Login / Session routes mapped to SessionsController
  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
end
