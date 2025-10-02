Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # 疎通確認 (GET /api/v1/ping -> {"ok":true})
      get "ping", to: "health#ping" #http://localhost:3333/api/v1/ping

      # 投稿内容取得
      resources :posts, only: [:index, :create, :show, :update, :destroy]
      # 投稿内容のリアクション取得・追加・削除
      resources :post_reactions, only: [:index, :create, :destroy, :show, :update]

      # ranking表示
      post "ranking", to: "ranking#create" #http://localhost:3333/api/v1/ranking
      get "ranking", to: "ranking#index"  #http://localhost:3333/api/v1/ranking

      # リアクションした投稿一覧取得
      resources :reacted_posts, only: [:index] # http://localhost:3333/api/v1/reacted_posts?user_id=1

      # signup
      post "signup", to: "signup#create" #http://localhost:3333/api/v1/signup

      # signin
      post "signin", to: "signin#create" #http://localhost:3333/api/v1/signin

      # make
      put "make/:id", to: "account#update" #http://localhost:3333/api/v1/make/:id

      # users
      resources :users, only: [:show, :update] #http://localhost:3333/api/v1/users/:id

      # search
      post "search", to: "search#index" #http://localhost:3333/api/v1/search

      # topics
      resources :topics, only: [:index, :create, :show, :update, :destroy]

      # report
      post "report", to: "report#judge" #http://localhost:3333/api/v1/report

      # point
      post "point", to: "points#update" #http://localhost:3333/api/v1/point

      # favorites
      resources :favorites, only: [:index, :show, :create]  #http://localhost:3333/api/v1/favorites
      post "favorites/delete", to: "favorites#delete" #http://localhost:3333/api/v1/favorites/delete

      # icon maker
      get "icon_maker/data_update", to: "icon_maker#data_update" #http://localhost:3333/api/v1/icon_maker/data_update # アイコンメーカーのデータ更新（ファイルの中身をDBに追加）

      # icon parts type
      resources :icon_parts_type, only: [:index]  #http://localhost:3333/api/v1/icon_parts_type # アイコンパーツの取得
      
      # icon parts
      resources :icon_parts, only: [:index]  #http://localhost:3333/api/v1/icon_parts # アイコンパーツの取得
    end
  end
end
