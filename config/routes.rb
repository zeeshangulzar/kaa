require 'resque/server'

Go::Application.routes.draw do
  
  root :to => "promotions#current"
  match '/promotions/current' => "promotions#current", :via => :get

  resources :resellers do
    resources :organizations, :only => [:index, :show]
  end

  match "/track" => "users#track", :via => :post
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

  match "/long_term_goals/curated_images" => "long_term_goals#curated_images", :via => :get
  match "/long_term_goals" => "long_term_goals#index", :via => :get
  match "/long_term_goals" => "long_term_goals#create", :via => :post
  match "/long_term_goals/:id" => "long_term_goals#show", :via => :get
  match "/long_term_goals/:id" => "long_term_goals#update", :via => :put
  

  match "/personal_action_plans" => "personal_action_plans#index", :via => :get
  match "/personal_action_plans" => "personal_action_plans#create", :via => :post

  resources :profiles, :only => [:update]

  resources :users do
    post 'forgot', :on => :collection
    collection do
      get 'search/:search_string', :to=>'users#search'
      get 'search', :to=>'users#search'
      post 'authenticate', :to => 'users#authenticate'
      post 'verify_password_reset' => 'users#verify_password_reset', :via => :post
      post 'impersonate' => 'users#impersonate', :via => :post
      put 'password_reset' => 'users#password_reset', :via => :put
    end
    resources :profiles, :only => [:update]
    resources :groups, :challenges_sent, :challenges_received, :suggested_challenges, :events
    resources :success_stories, :only => [:index, :show]
    resources :long_term_goals, :only => [:index, :show]
    resources :personal_action_plans, :only => [:index, :show]
    resources :team_invites
  end

  match '/get_user_from_auth_key/:auth_key' => 'users#get_user_from_auth_key', :via => :get

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
    resources :resources
    resources :banners
    resources :locations
    resources :reports
    resources :report_fields
    resources :report_joins
    resources :competitions
  end

  match 'promotions/:promotion_id/reports/:id/run', :controller => :reports, :action => :run, :via => :post

  # CONTENT MODELS
  resources :tips
  resources :articles
  resources :facts

  resources :resources
  resources :banners

  # locations...
  resources :locations do
    resources :locations, :only => [:index, :show]
    resources :forums
    resources :resources
    resources :banners
  end

  resources :forums
  

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

  
  match '*likeable_type/*likeable_id/user_like' => 'likes#user_like_show', :via => :get
  match '*likeable_type/*likeable_id/user_like' => 'likes#user_like_create', :via => [:post, :put]
  match '*likeable_type/*likeable_id/user_like' => 'likes#user_like_destroy', :via => :delete
  resources :likes
  match '*likeable_type/*likeable_id/likes' => 'likes#index', :via => :get
  match '*likeable_type/*likeable_id/likes' => 'likes#create', :via => :post
  match '*likeable_type/*likeable_id/likes' => 'likes#destroy', :via => :delete

  resources :photos
  match '*photoable_type/*photoable_id/photos' => 'photos#index', :via => :get
  match '*photoable_type/*photoable_id/photos' => 'photos#create', :via => :post
  match '*photoable_type/*photoable_id/photos' => 'photos#update', :via => :put
  match '*photoable_type/*photoable_id/photos' => 'photos#destroy', :via => :delete

  resources :shares
  match '*shareable_type/*shareable_id/shares' => 'shares#index', :via => :get
  match '*shareable_type/*shareable_id/shares' => 'shares#create', :via => :post

  match '*rateable_type/*rateable_id/user_rating' => 'ratings#user_rating_show', :via => :get
  match '*rateable_type/*rateable_id/user_rating' => 'ratings#user_rating_create', :via => [:post, :put]
  match '*rateable_type/*rateable_id/user_rating' => 'ratings#user_rating_destroy', :via => :delete
  resources :ratings
  match '*rateable_type/*rateable_id/ratings' => 'ratings#index', :via => :get
  match '*rateable_type/*rateable_id/ratings' => 'ratings#create', :via => :post
  
  match '/flagged_posts' => 'posts#flagged_posts', :via => :get

  match '*wallable_type/*wallable_id/popular_posts' => 'posts#popular_posts', :via => :get
  match '*wallable_type/*wallable_id/recent_posts' => 'posts#recent_posts', :via => :get

  resources :posts

  match '*wallable_type/*wallable_id/posts' => 'posts#index', :via => :get
	match '*wallable_type/*wallable_id/posts' => 'posts#create', :via => :post
	resources :wall_expert_posts
  
  # hes-recipes
  match "/recipes/favorites" => "recipes#user_favorites", :via => :get
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
 
  #kpwalk
  match 'kpw_users/enter' => 'kpw_users#enter', :via => 'post'
  match 'kpw_users/find_by_token' => 'kpw_users#find_by_token', :via => 'post'
  match 'kpw_users/authenticate' => 'kpw_users#authenticate', :via => 'post'
  match 'kpw_users/:id' => 'kpw_users#show', :via => 'get'

  mount Resque::Server.new, :at => "/resque"

  match "/emails/content" => "emails#content", :via => :post
  match "/emails/invite" => "emails#invite", :via => :post

  resources :contact_requests, :only => [:show, :create]

  resources :feedbacks, :only => :create

  resources :fitbits do
    collection do
      post :begin
      get :post_authorize
      post :disconnect
      post :refresh_week
      post :use_fitbit_data
      post :master_info
      post :notify
    end
  end

  match '/jawbones/:action', :controller => :jawbones

  match '/numbers' => "promotions#top_location_stats", :via => :get

  resources :teams do
    resources :team_members, :path => "members"
    resources :team_invites, :path => "invites"
    resources :team_photos, :path => "photos"
  end

  resources :competitions do
    resources :teams
  end

  resources :team_invites
  resources :team_photos
  resources :team_members

  match "/unsubscribe" => "emails#unsubscribe", :via => :post

  match "/send_mail" => "emails#send_mail", :via => :post
end
