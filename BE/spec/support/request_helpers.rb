module RequestHelpers
  def json
    response.parsed_body
  end

  def auth_headers(user)
    { "Authorization" => "Bearer #{user.auth_token}" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
