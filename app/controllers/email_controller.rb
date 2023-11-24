require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/gmail_v1'


class EmailController < ApplicationController
  OOB_URI = 'http://localhost:3000'.freeze
  APPLICATION_NAME = 'Email Monitoring'.freeze
  CLIENT_SECRETS_PATH = '/Users/romanciobanu/Downloads/client_secret_3.json'.freeze
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', 'gmail-ruby-quickstart.yaml').freeze
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY
  USER_ID = "me"

  def parse_emails
    text = ""
  end

  def connect_gmail
    # Set up the OAuth 2.0 client
    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    @authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    # user_id = 'me'


    credentials = @authorizer.get_credentials(USER_ID)

    if credentials.nil?

      url = @authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization:"
      puts url
      code = gets
      byebug

      credentials = @authorizer.get_and_store_credentials_from_code(user_id: USER_ID, code: code, base_url: OOB_URI)
    end


    service = Google::Apis::GmailV1::GmailService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = credentials

    result = service.list_user_messages(USER_ID)
    @message_data = messages(result.messages, service)
  end

  def callback
    puts params["code"]
    byebug
  end

  def messages(messages, service)
    messages.map.with_index do |message, index|
        full_message = service.get_user_message(USER_ID, message.id)

      {
        subject: full_message.payload.headers.find { |header| header.name == 'Subject' }&.value,
        sender: full_message.payload.headers.find { |header| header.name == 'From' }&.value,
        date: full_message.payload.headers.find { |header| header.name == 'Date' }&.value,
        receiver: full_message.payload.headers.find { |header| header.name == 'To' }&.value,
        message: full_message.payload.parts.first.body.data
      }
    rescue
    end
  end


  def connect_gmail_smpt
    @aaa = "aaa"
  end

end


 # subject = full_message.to_h[:payload][:headers].find { |header| header[:name] == 'Subject' }&.value
