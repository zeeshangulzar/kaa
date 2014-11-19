Go::Application.routes.draw do
  resources :resellers

  match "/users/validate/:field" => "users#validate", :via => :post
  match "/users/:user_id/profile" => "profiles#show", :via => :get
  match "/promotions/:promotion_id/users/search/:search_string" => "users#search", :via => :get

  resources :users do
    collection do
      get 'search/:search_string', :to=>'users#search'
    end
    resources :profiles, :only => [:update]
  end

  resources :promotions do
    resources :users, :only => [:index, :create, :search, :show]
  end
  
end
