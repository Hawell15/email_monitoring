require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/gmail_v1'
# require 'ruby-openai'
require 'openai'
require 'rest-client'
require 'json'

class EmailController < ApplicationController
   require "helpers/helper"

  OOB_URI = 'http://localhost:3000'.freeze
  APPLICATION_NAME = 'Email Monitoring'.freeze
  CLIENT_SECRETS_PATH = '/Users/romanciobanu/Downloads/client_secret_3.json'.freeze
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', 'gmail-ruby-quickstart.yaml').freeze
  SCOPE =['https://www.googleapis.com/auth/gmail.send', Google::Apis::GmailV1::AUTH_GMAIL_READONLY, 'https://www.googleapis.com/auth/gmail.modify']
  USER_ID = "me"

  def parse_emails
    text = ''
  end

  def connect_gmail
    service = connect_service
    start_date = '2023-11-11'
    end_date = '2023-11-26'


    result = service.list_user_messages(USER_ID, q: "after:#{start_date} before:#{end_date}")
    message_data = messages(result.messages, service)
    @data = message_data.reject(&:blank?).first(5).map do |message_hash|
        # message_hash[:subject][/\[OBG-\d+\]/] rescue byebug
      if message_hash[:subject][/\[HAC-\d+\]/]
        JiraService.new.add_comment(message_hash[:subject][/HAC-\d+/], message_hash[:message])
      # end
      else
        parsed_email = get_custom_email_category(message_hash) #NOTE: Custome categorized

        # parsed_email = parse_email(message_hash)

        next if !parsed_email || parsed_email[:category] == 'Other'

        JiraService.new.create_issue(parsed_email)
      end
    end
  end

  def ping_bank
    service = connect_service
    find_and_reply_to_email(service)
  end


  def callback
    puts params["code"]
    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    @authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    credentials = @authorizer.get_and_store_credentials_from_code(user_id: USER_ID, code: params["code"], base_url: OOB_URI)
    byebug

  end
  def messages(messages, service)
    messages.map.with_index do |message, _index|
      full_message = service.get_user_message(USER_ID, message.id)

      {
        subject: full_message.payload.headers.find { |header| header.name == 'Subject' }&.value,
        sender: full_message.payload.headers.find { |header| header.name == 'From' }&.value,
        date: full_message.payload.headers.find { |header| header.name == 'Date' }&.value,
        receiver: full_message.payload.headers.find { |header| header.name == 'To' }&.value,
        message: full_message.payload.parts.first.body.data
      }
    rescue StandardError
    end
  end

  def parse_email(message)
    openai_client = OpenAI::Client.new(api_key: '',
                                       default_engine: 'ada')

    user_message = <<~USER_MESSAGE
      Subject: "#{message[:subject]}"

      From: "#{message[:sender]}"
      To:"#{message[:receiver]}"
      Date: "#{message[:date]}"
      "#{message[:message]}"

    USER_MESSAGE

    delimiter = '####'
    system_message = <<~SYSTEM_MESSAGE
      You will be provided with banks service emails.
      The customer service query will be delimited with

      #{delimiter} characters.

      Classify each query into one of these categories:
      API updates, Certificates expired, Maintenance or Other.

      Parse the email and extract the following field names:
      bank_name, country, summary, category,

      Email: #{user_message}

      Provide your output in json format {"bank_name": "...", "country": "...", "summary": "....", "category": "..."  }
    SYSTEM_MESSAGE


    # response = client.chat(
    # parameters: {
    #     model: "gpt-3.5-turbo", # Required.
    #     messages: [{ role: "system", content: system_message}], # Required.
    #     temperature: 0.7,
    # })

    response = openai_client.completions(
      engine: 'text-davinci-003', # Use the appropriate engine
      prompt: system_message,
      max_tokens: 150 # Adjust as needed
    )

    json_data = response['choices'].first['text']
    data = JSON.parse(json_data)

    {
      subject: message[:subject],
      body: message[:message],
      bank_name: data['bank_name'],
      from: message[:sender],
      category: data['category']
    }
  rescue
  end

  def get_custom_email_category(message)
    notification_scope = /Notification|Notice|Reminder/i
    api_updates_scope  = /API (Updates|Changes|Enhancements|Modifications|Upgrades|Releases|Improvements|Versioning Changes)/i
    certificates_scope = /(?:Certificate).*?(?:Renewal|Revocation|Validity|Expir|Key|Generation)/i
    dates              = message[:message].scan(/(?:\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+\d{1,2})|\b(?:from?|until?) \d{1,2}\.\d{1,2}\.\d{4}\b/)

    category = if message[:subject][api_updates_scope] || message[:message][api_updates_scope]
      "API Updates"
    elsif message[:subject][notification_scope] ||  message[:message][notification_scope]
      "Notification"
    elsif message[:subject][certificates_scope] ||  message[:message][notification_scope]
      "Certificate"
    else
      "Other"
    end

    domains = [
      "us","uk","ca","au","fr","de","jp","cn","ru","br","in","it","mx","es","nl","kr","sa","se","ch",
      "pl","be","at","dk","fi","no","gr","cz","ro","hu","ar","tr","pt","nz","sg","za","ie","il","hk",
      "vn","cl","id","ua","ae","tw","th","co","ma","eg","my","ph","pe","rs","hr","ve","pk","bg","sk",
      "lt","si","do","lv","by","ng","ba","ke","cr","cy","tn","lu","ec","gt","uy","py","sv","hn","bo",
      "md","et","jm","mu","bw","np","iq","lk","gh","am","kw","lb","tz","zm","mg","kg","ug","bn","me",
      "gy","al","ug","dz","ni","cd","mo","kh","ht","bw","rw"
    ]
    row_email_domain   = message[:sender].split("@").last
    email_domain       = row_email_domain.split(".").last
    bank_name          = row_email_domain.split(".").first.capitalize
    email_country_code = domains.detect { |country| country == email_domain }
    country_code       = email_country_code.nil? ? "NaN" : email_country_code

    compress({
      subject: message[:subject],
      body: parse_description(message[:message]),
      bank_name: bank_name,
      from: message[:sender],
      category: category,
    })
  end

  def find_and_reply_to_email(service)
    subject_keywords = "This is the subject"
    partial_subject = subject_keywords.first(15)
    # Find the email by subject keywords
    messages = service.list_user_messages('me', q: "from:roma.ciobanu@gmail.com in:inbox" )
    # messages = service.list_user_messages('me', q: "subject:#{subject_keywords}")
    # messages = service.list_user_messages('me', q: "subject:#{partial_subject}")
    # messages = service.list_user_messages('me', q: "subject:#{subject_keywords} in:inbox")

    return if messages.messages.nil? || messages.messages.empty?


    matching_messages = messages.messages.detect do |message|
      full_message = service.get_user_message(USER_ID, message.id)
      subject_header = full_message.payload.headers.find { |header| header.name == 'Subject' }
      subject_header && subject_header.value.include?(partial_subject) &&
      full_message.payload.headers.find { |header| header.name == 'From' }.value.exclude?("bazaorientare@gmail.com")
    end



    # Retrieve the first message
    original_message_id = matching_messages.id
    original_email = service.get_user_message('me', original_message_id)

    # Get the sender's email address
    sender_email = original_email.payload.headers.find { |header| header.name == 'From' }.value

    # Create the reply using the Mail gem
    reply_mail = Mail.new do
      from 'bazaorientare@gmail.com'  # Set your email address
      to sender_email
      subject original_email.payload.headers.find { |header| header.name == 'Subject' }.value
      body "Hello Team, \n Do you have any updates? \n Kind regards"

      # " + "\n\n" + original_email.snippet
      references original_email.payload.headers.find { |header| header.name.downcase == 'message-id' }.value
      in_reply_to original_email.payload.headers.find { |header| header.name.downcase == 'message-id' }.value
    end

    # Convert the Mail message to raw format
    raw_reply = reply_mail.to_s

    # Create the Gmail message for the reply
    reply_message = Google::Apis::GmailV1::Message.new(raw: raw_reply, thread_id: original_email.thread_id)

    # Send the reply
    service.send_user_message('me', reply_message)
  rescue => error
  end

  def connect_service
    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    @authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    credentials = @authorizer.get_credentials(USER_ID)

    if credentials.nil?

      url = @authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization:"
      puts url
      return
      # code = gets
      byebug

      credentials = @authorizer.get_and_store_credentials_from_code(user_id: USER_ID, code: code, base_url: OOB_URI)
    end

    service = Google::Apis::GmailV1::GmailService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = credentials
    service
  end

  def compress(hash)
    hash.reject { |_key, value| value.nil? || value.empty? }
  end

  def normalize_string(string)
    # return "" if string.nil?
    # string.gsub(/[−–]/, "-").squeeze(' ').strip
  end

  def parse_description(string)
    normalize_string(string.gsub(/[\s]/, ' '))
  end
end

# subject = full_message.to_h[:payload][:headers].find { |header| header[:name] == 'Subject' }&.value
