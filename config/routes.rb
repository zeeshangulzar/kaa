Go::Application.routes.draw do
  resources :resellers do
    resources :organizations, :only => [:index, :show]
  end

  match "/users/validate" => "users#validate", :via => :post
  match "/users/:user_id/profile" => "profiles#show", :via => :get
  match "/promotions/:promotion_id/users/search/:search_string" => "users#search", :via => :get
  match 'users/:user_id/entries' => 'entries#index', :via => :get
  match "/files/upload" => "files#upload", :via => :post
  match "/files/crop" => "files#crop", :via => :put

  resources :users do
    collection do
      get 'search/:search_string', :to=>'users#search'
      post 'authenticate', :to => 'users#authenticate'
    end
    resources :profiles, :only => [:update]
    resources :groups, :challenges_sent, :challenges_received
  end

  resources :challenges, :organizations, :group_users

  resources :challenges_sent
  resources :challenges_received

  resources :groups do
    resources :group_users, :only => [:index, :show]
  end

  resources :promotions do
    resources :users, :only => [:index, :create, :search, :show]
    resources :activities, :only => [:index, :create, :show]
    resources :challenges, :only => [:index, :show]
  end

  # locations...
  resources :locations
  match '*locationable_type/*locationable_id/locations' => "locations#index", :via => :get
  match '*locationable_type/*locationable_id/locations' => "locations#create", :via => :post
  match '*locationable_type/*locationable_id/locations/upload' => "locations#upload", :via => :post

  # friendships...
  resources :friendships
  match '*friendable_type/*friendable_id/friendships' => 'friendships#index', :via => :get
  match '*friendable_type/*friendable_id/friendships' => 'friendships#show', :via => :get
  match '*friendable_type/*friendable_id/friendships/*friendship_id' => 'friendships#show', :via => :get
  match '*friendable_type/*friendable_id/friendships' => 'friendships#create', :via => :post

  resources :entries

  resources :evaluation_definitions do
		resources :evaluations, :only => [:index, :create]
	end

	match 'promotions/:promotion_id/evaluation_definitions' => 'evaluation_definitions#index', :via => :get
	match 'promotions/:promotion_id/evaluation_definitions' => 'evaluation_definitions#create', :via => :post

	resources :evaluations
	match 'promotions/:promotion_id/evaluations' => 'evaluations#index', :via => :get
  
end
