require 'resque/server'

Go::Application.routes.draw do

  root :to => "promotions#current"
  match '/promotions/current' => "promotions#current", :via => :get

  resources :resellers do
    resources :organizations, :only => [:index, :show]
    resources :promotions, :only => [:index, :show]
  end

  match "/track" => "users#track", :via => :post
  match "/users/validate" => "users#validate", :via => :post
  match "/users/:user_id/profile" => "profiles#show", :via => :get
  match "/promotions/:promotion_id/users/search/:search_string" => "users#search", :via => :get
  match '/users/:user_id/entries' => 'entries#index', :via => :get

  match "/files/upload" => "files#upload", :via => :post
  match "/files/crop" => "files#crop", :via => :put
  match "/files/rotate" => "files#rotate", :via => :post

  match "/stats" => "users#stats", :via => :get
  match "/users/:id/stats" => "users#stats", :via => :get

  resources :profiles, :only => [:update]

  match "/individual_leaderboard" => "users#leaderboard", :via => :get
  match "/promotions/:promotion_id/individual_leaderboard" => "users#leaderboard", :via => :get
  match "/promotions/:promotion_id/can_register" => "promotions#can_register", :via => :get

  match "/competitions/:id/members" => "competitions#members", :via => :get

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
    resources :team_invites
    resources :friendships
  end

  match '/get_user_from_auth_key/:auth_key' => 'users#get_user_from_auth_key', :via => :get

  resources :organizations do
    resources :promotions, :only => [:index, :show]
  end

  get '/facts/current', :to=>'facts#current'
  get '/promotions/:promotion_id/facts/current', :to=>'facts#current'
  post '/promotions/:promotion_id/one_time_email', :to=>'promotions#one_time_email'

  match 'promotions/get_grouped_promotions', :controller => :promotions, :action => :get_grouped_promotions, :via => :get

  resources :promotions do
    post 'authenticate', :to => 'promotions#authenticate'
    resources :users, :only => [:index, :create, :search, :show]
    resources :activities, :only => [:index, :create, :show]
    resources :behaviors, :only => [:index, :create, :show]
    resources :custom_content, :controller => "custom_content"
    resources :eligibilities
    resources :eligibility_files
    resources :tips
    resources :facts
    resources :articles
    resources :locations
    resources :reports
    resources :report_fields
    resources :report_joins
    resources :competitions
    resources :maps
    resources :levels
  end

  get "promotions/:promotion_id/level_summary", :to => "levels#summary"

  match 'promotions/:promotion_id/reports/:id/run', :controller => :reports, :action => :run, :via => :post

  match 'promotions/:promotion_id/behaviors/reorder', :controller => :behaviors, :action => :reorder, :via => :post

  match 'promotions/:promotion_id/tips/reorder', :controller => :tips, :action => :reorder, :via => :post
  match "/tips/favorites" => "tips#user_favorites", :via => :get

  # CONTENT MODELS
  resources :tips
  resources :articles
  resources :facts
  resources :custom_content, :controller => "custom_content"

  match 'promotions/:promotion_id/custom_content/reorder' => 'custom_content#reorder', :via => :post
  match 'custom_content/copy' => 'custom_content#copy', :via => :post

  resources :behaviors

  # locations...
  resources :locations do
    resources :locations, :only => [:index, :show]
  end

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
  match '*notificationable_type/*notificationable_id/notifications' => 'notifications#keyed_notifications', :via => :get
  match '*notificationable_type/*notificationable_id/notifications' => 'notifications#create', :via => :post
  match '*notificationable_type/*notificationable_id/notifications/:id' => 'notifications#destroy', :via => :delete


  match '*likeable_type/*likeable_id/user_like' => 'likes#user_like_show', :via => :get
  match '*likeable_type/*likeable_id/user_like' => 'likes#user_like_create', :via => [:post, :put]
  match '*likeable_type/*likeable_id/user_like' => 'likes#user_like_destroy', :via => :delete
  resources :likes
  match '*likeable_type/*likeable_id/likes' => 'likes#index', :via => :get
  match '*likeable_type/*likeable_id/likes' => 'likes#create', :via => :post
  match '*likeable_type/*likeable_id/likes' => 'likes#destroy', :via => :delete

  match "all_team_photos" => 'photos#all_team_photos', :via => :get
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

  match "/posters/current" => "posters#current", :via => :get
  resources :posters

  resources :launch_notifications, :only => [:create]

  mount Resque::Server.new, :at => "/resque"

  match "/emails/content" => "emails#content", :via => :post
  match "/emails/invite" => "emails#invite", :via => :post

  resources :contact_requests, :only => [:show, :create]

  resources :feedbacks, :only => :create

  resources :fitbits do
    collection do
      post :begin
      get :post_authorize
      get :callback2
      post :disconnect
      post :refresh_week
      post :use_fitbit_data
      post :master_info
      post :notify
      get :notify
      post :get_daily_summaries
    end
  end
  match 'fitbit/:action', :controller => :fitbits
  match '/jawbones/:action', :controller => :jawbones

  match '/numbers' => "promotions#top_location_stats", :via => :get

  resources :teams do
    resources :team_members, :path => "members"
    resources :team_invites, :path => "invites"
  end

  resources :competitions do
    resources :teams
  end

  resources :team_invites
  resources :team_members
  resources :chat_messages

  match '*chat_messages/hide_conversation' => 'chat_messages#hide_conversation', :via => :post

  match "/unsubscribe" => "emails#unsubscribe", :via => :post

  match "/send_mail" => "emails#send_mail", :via => :post

  match "/export" => "exports#index", :via => :post

  match 'promotions/:promotion_id/keywords' => 'promotions#keywords', :via => :get

  match "/store" => "store#index", :via => :get, :controller => :store
  match "/store/place_order" => "store#place_order", :via => :post, :controller => :store


  resources :eligibilities
  match "/promotions/:id/eligibilities/validate" => "eligibilities#validate", :via => :post
  match "/promotions/:id/eligibilities/upload" => "eligibilities#upload", :via => :post
  match "/eligibilities/validate" => "eligibilities#validate", :via => :post
  match "/eligibilities/upload" => "eligibilities#upload", :via => :post
  resources :eligibility_files
  match "/eligibility_files/:eligibility_file_id/process" => "eligibility_files#start_job", :via => :post
  match "/promotions/:id/eligibility_files/:eligibility_file_id/process" => "eligibility_files#start_job", :via => :post
  match "eligibility_files/:eligibility_file_id/download" => "eligibility_files#download", :via => :get
  match "/promotions/:id/eligibility_files/:eligibility_file_id/download" => "eligibility_files#download", :via => :get

  match "/sso" => "sso#index"

  # friendships...
  resources :friendships

  resources :maps do
    resources :routes
    resources :destinations
  end
  resources :routes
  resources :destinations

  match "/promotions/:promotion_id/update_maps" => "maps#update_maps", :via => :post
  match "/maps/:map_id/upload" => "maps#upload", :via => :post

  match "/users/:user_id/destinations" => "destinations#user_destinations", :via => :get
  match "/users/:user_id/destinations/:destination_id" => "destinations#user_destinations", :via => :get

  match "/destinations/:destination_id/answer" => "destinations#answer", :via => :post

  match "/notifications/mark_as_seen" => "notifications#mark_as_seen", :via => :post
  match "/notifications/mark_as_read" => "notifications#mark_as_read", :via => :post

  # image galleries
  match 'gallery_images/' => 'gallery_images#index', :via => :get
  match 'gallery_images/:file' => 'gallery_images#index', :via => :get, :constraints => { :file => /[^\/]+/ }
  match 'gallery_images/*path/:file' => 'gallery_images#index', :via => :get, :constraints => { :file => /[^\/]+/ }
  match 'gallery_images/:file' => 'gallery_images#update', :via => :put, :constraints => { :file => /[^\/]+/ }
  match 'gallery_images/*path/:file' => 'gallery_images#update', :via => :put, :constraints => { :file => /[^\/]+/ }
  match 'gallery_images/:file' => 'gallery_images#destroy', :via => :delete, :constraints => { :file => /[^\/]+/ }
  match 'gallery_images/*path/:file' => 'gallery_images#destroy', :via => :delete, :constraints => { :file => /[^\/]+/ }
  match "gallery_images/" => 'gallery_images#create', :via => :post
  match "gallery_images/*path/" => 'gallery_images#create', :via => :post

  match "conversations/" => 'conversations#create', :via => :post
  match "conversations/:conversation_id/messages" => 'conversations#messages', :via => :post
  match "/users/:user_id/conversation_summary" => 'users#conversation_summary', :via => :get


end
