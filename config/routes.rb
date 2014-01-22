VxWeb::Application.routes.draw do

  namespace :api do

    resources :users do
      collection do
        get :me
      end
    end

    resources :projects do
      resources :builds, only: [:index, :create]
      resources :cached_files, only: [:index]
      resource :subscription, only: [:create, :destroy], controller: "project_subscriptions"
    end

    resources :builds, only: [:show] do
      member do
        post :restart
      end
      resources :jobs, only: [:index]
    end

    resources :jobs, only: [:show] do
      resources :logs, only: [:index], controller: "job_logs"
    end

    resources :cached_files, only: [:destroy]

    resources :github_repos, only: [:index] do
      member do
        post :subscribe
        post :unsubscribe
      end
      collection do
        post :sync
      end
    end
  end

  put "cached_files/u/:token/*file_name.:file_ext", to: "api/cached_files#upload"
  get "cached_files/u/:token/*file_name.:file_ext", to: "api/cached_files#download"

  post '/:_service/callback/:token', to: 'repo_callbacks#create', _service: /(github)/

  get '/auth/github/callback', to: 'github/user_callbacks#create'
  get '/auth/failure', to: redirect('/')

  get '/sse_events', to: 'sse_events#index'

  root 'welcome#index'

  get "*path", to: "welcome#index", constraints: ->(req) { req.format == Mime::HTML }
end
