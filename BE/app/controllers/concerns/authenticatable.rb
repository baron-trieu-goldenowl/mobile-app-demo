# Bearer-token (JWT) authentication for API controllers.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  attr_reader :current_user

  def authenticate_user!
    payload = JsonWebToken.decode(bearer_token) if bearer_token
    @current_user = User.find_by(id: payload["user_id"]) if payload
    render_error("Unauthorized", :unauthorized) unless @current_user
  end

  def bearer_token
    request.headers["Authorization"].to_s[/\ABearer (.+)\z/, 1]
  end
end
