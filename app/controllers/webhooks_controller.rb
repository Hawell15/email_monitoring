class WebhooksController < ApplicationController
  skip_forgery_protection

  def ping
    puts "Ping"
    head :ok
  end
end
