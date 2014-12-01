Go::Application.routes.draw do
  resources :resellers do
    resources :organizations, :only => [:index, :show]
  end

  match "/users/validate/:field" => "users#validate", :via => :post
  match "/users/:user_id/profile" => "profiles#show", :via => :get
  match "/promotions/:promotion_id/users/search/:search_string" => "users#search", :via => :get
  match 'users/:user_id/entries' => 'entries#index', :via => :get

  resources :users do
    collection do
      get 'search/:search_string', :to=>'users#search'
      post 'authenticate', :to => 'users#authenticate'
    end
    resources :profiles, :only => [:update]
  end

  resources :promotions do
    resources :users, :only => [:index, :create, :search, :show]
  end
  
end
