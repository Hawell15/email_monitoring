class JiraService
  BASE_URL = 'https://saltedge.atlassian.net'

  def initialize
    @username = Settings.jira.username
    @api_token = Settings.jira.api_token
  end

  def create_issue(parsed_email_data_json)
    subject   = parsed_email_data_json['subject']
    body      = parsed_email_data_json['body']
    bank_name = parsed_email_data_json['bank_name']
    from      = parsed_email_data_json['from']

    information_source = bank_name || from
    summary            = information_source.present? ? "[#{information_source}]: #{subject}" : subject

    issue_data = {
      fields: {
        project: {
          key: 'HAC'
        },
        issuetype: {
          name: 'Task'
        },
        summary: summary,
        description: body
      }
    }

    request(:post, "#{BASE_URL}/rest/api/2/issue", payload: issue_data)
  end

  def add_comment(issue_id, body)
    request(:post, "#{BASE_URL}/rest/api/2/issue/#{issue_id}/comment", payload: { body: body })
  end

  private

  def request(method, url, params = {})
    response = RestClient::Request.execute(
      method: method,
      url: url,
      payload: params[:payload].to_json,
      headers: {
        'Accept' => 'application/json',
        'Content-type' => 'application/json',
        'Authorization' => "Basic #{Base64.strict_encode64("#{@username}:#{@api_token}")}"
      }
    )

    JSON.parse(response.body)
  rescue RestClient::Exception => e
    Rails.logger.error("Error: #{e.message}, Response: #{e.response}")

    raise
  end
end
