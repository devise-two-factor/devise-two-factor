Rails.application.routes.draw do
  get 'home/index'
  post 'users/enable_otp'
  post 'users/disable_otp'

  devise_for :users

  root to: "home#index", via: [:get, :post]
end
