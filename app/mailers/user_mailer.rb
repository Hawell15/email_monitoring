class UserMailer < ApplicationMailer
  default from: 'bazaorientare@gmail.com'

  def welcome_email(user)
    # @user = user
    # @url  = 'http://yourapp.com/login'
    mail(to: "roma.ciobanu@gmail.com", subject: 'Welcome to My Awesome Site')
  end
end
