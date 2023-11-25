require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/gmail_v1'
require 'openai'
require 'rest-client'
require 'json'

<<<<<<< HEAD
require_relative 'helpers/helper.rb'



=======
>>>>>>> e74282f (Removed unnecesary methods and did a small refactoring)
class EmailController < ApplicationController
   include Helper

  OOB_URI = 'http://localhost:3000'.freeze
  APPLICATION_NAME = 'Email Monitoring'.freeze
  CLIENT_SECRETS_PATH = '/Users/romanciobanu/Downloads/client_secret_3.json'.freeze
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', 'gmail-ruby-quickstart.yaml').freeze
  SCOPE = Google::Apis::GmailV1::AUTH_GMAIL_READONLY
  USER_ID = "me"

<<<<<<< HEAD
  def connect_gmaila
=======
  def parse_emails
    text = ""
  end

  def connect_gmail
>>>>>>> e74282f (Removed unnecesary methods and did a small refactoring)
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
    start_date = '2023-11-23'
    end_date = '2023-11-25'

    result = service.list_user_messages(USER_ID, q: "after:#{start_date} before:#{end_date}")
    message_data = messages(result.messages, service)
    @data = message_data.map do |message_hash|
      if message_hash[:subject][/\[OBG-\d+\]/]
        JiraService.new.add_comment(message_hash)
      else
        # parsed_email = get_custom_email_category(message_hash) #NOTE: Custome categorized

        parsed_email = parse_email(message_hash)
        JiraService.new.create_issue(parsed_email)
      end
    end
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

  def parse_email(message)
    openai_client = OpenAI::Client.new(api_key: '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', default_engine: "ada")

    user_message = <<~USER_MESSAGE
      Subject: "#{message[:subject]}"

      From: "#{message[:sender]}"
      To:"#{message[:receiver]}"
      Date: "#{message[:date]}"
      "#{message[:message]}"

    USER_MESSAGE

    delimiter = "####"
    system_message = <<~SYSTEM_MESSAGE
      You will be provided with banks service emails.
      The customer service query will be delimited with

      #{delimiter} characters.

      Classify each query into one of these categories:
      API updates, Downtime information, Maintenance or Other.

      Parse the email and extract the following field names:
      bank_name, country, summary, category,

      Email: #{user_message}

      Provide your output in json format {"bank_name": "...", "country": "...", "summary": "....", "category": "..."  }
    SYSTEM_MESSAGE



    response = openai_client.completions(
      engine: 'text-davinci-003',  # Use the appropriate engine
      prompt: system_message,
      max_tokens: 150  # Adjust as needed
    )

    json_data = response["choices"].first["text"]
    data = JSON.parse(json_data)

    {
      category: data["category"],
      country_code:data["country_code"],
      bank_name: data["bank_name"],
      description: message[:message],
      summary: data["summary"]

    }
  end

  def get_custom_email_category(message)
    notification_scope = /Notification|Notice|Reminder/i
    api_updates_scope  = /API (Updates|Changes|Enhancements|Modifications|Upgrades|Releases|Improvements|Versioning Changes)/i
    certificates_scope = /(?:Certificate).*?(?:Renewal|Revocation|Validity|Expir|Key|Generation)/i
    dates              = message[:message].scan(/(?:\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+\d{1,2})|\b(?:from?|until?) \d{1,2}\.\d{1,2}\.\d{4}\b/)

    category = if message[:subject][api_updates_scope]
      "API Updates"
    elsif message[:subject][notification_scope]
      "Notification"
    elsif message[:subject][certificates_scope]
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
      category: category,
      country_code: country_code,
      bank_name: email_domain,
      description: parse_description(message[:message]),
      summary: dates
    })
  end


  def connect_gmail
    openai_client = OpenAI::Client.new(api_key: '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', default_engine: "ada")

    html_content = File.read('/Users/romanciobanu/Downloads/20230513_Чемпионат и сопутка.html')

    doc = Nokogiri::HTML(html_content)
    text_content = doc.text

    prompt = "In document is results from orienteering competition, Process the following text:\n#{ groups[1].map(&:text)} and extract all information about group, runners and results. Show data in JSON format"

    data = {}
    trs = doc.css("tr").reject { |tr| tr.text.blank? }
    groups = trs.slice_before { |tr| tr.text.include?('Categoria de v') }.to_a

    byebug

    response = openai_client.completions(
      engine: 'text-davinci-003',  # Use the appropriate engine
      prompt: prompt,
      max_tokens: 10 # Adjust as needed
    )

  end
end


 # subject = full_message.to_h[:payload][:headers].find { |header| header[:name] == 'Subject' }&.value
