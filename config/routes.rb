Go::Application.routes.draw do
  resources :resellers do
    resources :organizations, :only => [:index, :show]
  end

  match "/users/validate" => "users#validate", :via => :post
  match "/users/:user_id/profile" => "profiles#show", :via => :get
  match "/promotions/:promotion_id/users/search/:search_string" => "users#search", :via => :get
  match 'users/:user_id/entries' => 'entries#index', :via => :get
  match "/files/upload" => "files#upload", :via => :post

  resources :users do
    collection do
      get 'search/:search_string', :to=>'users#search'
      post 'authenticate', :to => 'users#authenticate'
    end
    resources :profiles, :only => [:update]
  end

  resources :promotions do
    resources :users, :only => [:index, :create, :search, :show]
    resources :activities, :only => [:index, :create, :show]
  end

  resources :organizations

  # locations...
  resources :locations
  match '*locationable_type/*locationable_id/locations' => "locations#index", :via => :get
  match '*locationable_type/*locationable_id/locations' => "locations#create", :via => :post
  match '*locationable_type/*locationable_id/locations/upload' => "locations#upload", :via => :post
  
end