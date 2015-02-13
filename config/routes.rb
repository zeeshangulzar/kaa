require 'resque/server'

Go::Application.routes.draw do
  
  root :to => "promotions#current"
  match '/promotions/current' => "promotions#current", :via => :get

  resources :resellers do
    resources :organizations, :only => [:index, :show]
  end

  match "/users/validate" => "users#validate", :via => :post
  match "/users/:user_id/profile" => "profiles#show", :via => :get
  match "/promotions/:promotion_id/users/search/:search_string" => "users#search", :via => :get
  match '/users/:user_id/entries' => 'entries#index', :via => :get
  
  match '/entries/aggregate' => 'entries#aggregate', :via => :get
  match '/entries/aggregate/:year' => 'entries#aggregate', :via => :get

  match "/files/upload" => "files#upload", :via => :post
  match "/files/crop" => "files#crop", :via => :put

  match "/stats" => "users#stats", :via => :get
  match "/users/:id/stats" => "users#stats", :via => :get

  resources :users do
    collection do
      get 'search/:search_string', :to=>'users#search'
      get 'search', :to=>'users#search'
      post 'authenticate', :to => 'users#authenticate'
    end
    resources :profiles, :only => [:update]
    resources :groups, :challenges_sent, :challenges_received, :suggested_challenges, :events
    resources :success_stories, :only => [:index, :show]
  end

  match 'badges' => 'badges#user_badges_earned', :via => 'get'
  match 'users/:user_id/badges' => 'badges#user_badges_earned', :via => 'get'

  resources :badges

  match "challenges_sent/validate" => "challenges_sent#validate", :via => 'post'

  resources :challenges, :organizations, :group_users, :challenges_sent, :challenges_received, :suggested_challenges

  match 'groups/*group_id/users' => 'group_users#index', :via => :get
  resources :groups do
    resources :group_users, :only => [:index, :show]
  end

  get '/facts/current', :to=>'facts#current'
  get '/promotions/:promotion_id/facts/current', :to=>'facts#current'

  resources :promotions do
    resources :users, :only => [:index, :create, :search, :show]
    resources :activities, :only => [:index, :create, :show]
    resources :challenges, :only => [:index, :show]
    resources :suggested_challenges, :only => [:index, :show]
    resources :posters, :only => [:index, :show]
    resources :success_stories, :only => [:index, :show]
    resources :badges, :only => [:index]
    # CONTENT MODELS
    resources :tips
    resources :facts
    resources :articles
  end

  # CONTENT MODELS
  resources :tips
  resources :articles
  resources :facts

  # locations...
  resources :locations do
    resources :locations, :only => [:index, :show]
  end
  

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

  resources :custom_prompts
  match '*custom_promptable_type/*custom_promptable_id/custom_prompts' => 'custom_prompts#index', :via => :get
  match '*custom_promptable_type/*custom_promptable_id/custom_prompts' => 'custom_prompts#create', :via => :post

  match '/notifications/get_past_notifications' => 'notifications#get_past_notifications', :via => :get
  resources :notifications
  match "/notifications" => "notifications#update", :via => :put
  match '*notificationable_type/*notificationable_id/notifications' => 'notifications#index', :via => :get
  match '*notificationable_type/*notificationable_id/notifications' => 'notifications#create', :via => :post
  match '*notificationable_type/*notificationable_id/notifications/:id' => 'notifications#destroy', :via => :delete

  resources :likes
  match '*likeable_type/*likeable_id/likes' => 'likes#index', :via => :get
  match '*likeable_type/*likeable_id/likes' => 'likes#create', :via => :post
  match '*likeable_type/*likeable_id/likes' => 'likes#destroy', :via => :delete
  
  match '/flagged_posts' => 'posts#flagged_posts', :via => :get
	match '*wallable_type/*wallable_id/popular_posts' => 'posts#popular_posts', :via => :get
	resources :posts
	match '*wallable_type/*wallable_id/posts' => 'posts#index', :via => :get
	match '*wallable_type/*wallable_id/posts' => 'posts#create', :via => :post
	resources :wall_expert_posts

  # hes-recipes
  match "/recipes/daily" => "recipes#show", :daily => true
  match "/recipes/first" => "recipes#show", :first => true
  match "/recipes/last" => "recipes#show", :last => true
  match "/recipes/browse/:category" => "recipes#browse"
  match "/recipes/search/:search" => "recipes#search"
  resources :recipes, :only => [:index, :show]

  # hes-commentable
  resources :comments
  match '*commentable_type/*commentable_id/comments' => 'comments#index', :via => :get
  match '*commentable_type/*commentable_id/comments' => 'comments#create', :via => :post

  resources :events do
    resources :invites, :only => [:index, :show, :create]
  end
  resources :invites

  resources :chat_messages

  match "/posters/current" => "posters#current", :via => :get
  resources :posters

  match "/success_stories/featured" => "success_stories#featured", :via => :get
  resources :success_stories

  resources :launch_notifications, :only => [:create]
  
  mount Resque::Server.new, :at => "/resque"

end
