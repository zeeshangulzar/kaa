Go::Application.routes.draw do
  resources :resellers

  resources :users do
    collection do
      get 'search/:search_string', :to=>'users#search'
    end
  end
end
