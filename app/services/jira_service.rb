class JiraService
  BASE_URL      = 'https://saltedge.atlassian.net'
  PROJECT_NAME  = 'HAC'

  def initialize
    @username = Settings.jira.username
    @token = Settings.jira.token
  end

  def create_issue(parsed_email)
    request(:post, "#{BASE_URL}/rest/api/2/issue", payload: new_issue_payload(parsed_email))
  end

  def add_comment(issue_id, body)
    request(:post, "#{BASE_URL}/rest/api/2/issue/#{issue_id}/comment", payload: { body: body })
  end

  private

  def new_issue_payload(parsed_email)
    subject   = parsed_email[:subject]
    body      = parsed_email[:body]
    bank_name = parsed_email[:bank_name]
    from      = parsed_email[:from]
    category  = parsed_email[:category]

    information_source = bank_name || from
    summary            = "[#{category}]: #{subject}"
    summary            = "[#{information_source}]#{summary}" if information_source.present?

    {
      fields: {
        project: {
          key: PROJECT_NAME
        },
        issuetype: {
          name: 'Task'
        },
        summary: summary,
        description: body
      }
    }
  end

  def request(method, url, params = {})
    response = RestClient::Request.execute(
      method: method,
      url: url,
      payload: params[:payload].to_json,
      headers: {
        'Accept' => 'application/json',
        'Content-type' => 'application/json',
        'Authorization' => "Basic #{Base64.strict_encode64("#{@username}:#{@token}")}"
      }
    )

    JSON.parse(response.body)
  rescue RestClient::Exception => e
    Rails.logger.error("Error: #{e.message}, Response: #{e.response}")

    raise
  end
end
