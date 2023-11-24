class JiraService
  BASE_URL = 'https://saltedge.atlassian.net'

  def initialize
    @username = ENV['JIRA_USERNAME']
    @api_token = ENV['JIRA_API_TOKEN']
  end

  def create_issue
    summary = "Task Summary #{Time.now.to_i}"
    description = "Task Description #{Time.now.to_i}"

    issue_data = {
      fields: {
        project: {
          key: 'HAC'
        },
        summary: summary,
        issuetype: {
          name: 'Task'
        },
        customfield_10180: {
          value: 'Other'
        },
        description: description,
        customfield_10000: 'Your Development Value',
        customfield_10500: 'www.saltedge.com'
      }
    }

    request(:post, "#{BASE_URL}/rest/api/2/issue", payload: issue_data)
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
