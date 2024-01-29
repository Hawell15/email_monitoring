Rails.application.routes.draw do
  get 'email/parse_emails'
  get 'email/ping_bank'
  # post 'email/ping_bank'
  get 'email/connect_gmail_smpt'
  get 'oauth2callback', to: "email#callback"
  get 'email/connect_gmail'
  get 'auth/:provider/callback', to: 'sessions#googleAuth'
  get 'auth/failure', to: redirect('/')
  get 'email/index'

  namespace :webhooks do
    post :ping
  end
end
