Rails.application.routes.draw do
  get 'email/parse_emails'
  get 'email/ping_bank'
  get 'email/connect_gmail_smpt'
  get 'oauth2callback', to: "email#callback"
  get 'email/connect_gmail'
  get 'auth/:provider/callback', to: 'sessions#googleAuth'
  get 'auth/failure', to: redirect('/')

  namespace :webhooks do
    post :ping
  end
end
