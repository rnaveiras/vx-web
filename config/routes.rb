VxWeb::Application.routes.draw do

  namespace :api do

    resources :users do
      collection do
        get :me
      end
    end

    namespace :user_identities do
      resources :gitlab, only: [:update, :create, :destroy]
    end

    resources :projects do
      resources :builds, only: [:index, :create]
      resources :cached_files, only: [:index]
      resource :subscription, only: [:create, :destroy], controller: "project_subscriptions"
      member do
        get "key"
      end
    end

    resources :builds, only: [:show] do
      member do
        post :restart
      end
      collection do
        get "sha/:sha", action: :sha, as: :sha
      end
      resources :jobs, only: [:index]
      resources :artifacts, only: [:index]
    end

    resources :jobs, only: [:show] do
      resources :logs, only: [:index], controller: "job_logs"
    end

    resources :user_repos, only: [:index] do
      member do
        post :subscribe
        post :unsubscribe
      end
      collection do
        post :sync
      end
    end

    resources :cached_files, only: [:destroy]
    resources :artifacts, only: [:destroy]
    resources :status, only: [:show], id: /(jobs)/
    resources :events, only: [:index]
  end

  get    '/auth/github/callback', to: "user_session/github#callback"
  get    '/auth/failure',         to: redirect('/')
  delete '/auth/session',         to: "user_session/session#destroy"

  put "/f/cached_files/:token/*file_name.:file_ext", to: "api/cached_files#upload", as: :upload_cached_file
  get "/f/cached_files/:token/*file_name.:file_ext", to: "api/cached_files#download"

  put "/f/artifacts/:build_id/:token/*file_name.:file_ext", to: "api/artifacts#upload", as: :upload_artifact
  get "/f/artifacts/:build_id/:token/*file_name.:file_ext", to: "api/artifacts#download"

  post '/callbacks/:_service/:_token', to: 'repo_callbacks#create', _service: /(github|gitlab)/,
    as: 'repo_callback'

  get "builds/sha/:sha" => "builds#sha"

  get '/welcome/sign_up', to: "welcome#sign_up", as: :sign_up

  scope constraints: ->(req){ req.format == Mime::HTML } do
    get "/",         to: redirect("/ui")
    get "/ui",       to: "welcome#show"
    get "/ui/*path", to: "welcome#show"
  end
end
