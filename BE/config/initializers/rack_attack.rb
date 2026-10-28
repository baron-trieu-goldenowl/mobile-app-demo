# Throttle authentication endpoints to slow down credential stuffing.
class Rack::Attack
  AUTH_PATHS = %r{\A/api/v1/auth/}

  throttle("auth/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.post? && AUTH_PATHS.match?(req.path)
  end

  throttle("api/ip", limit: 300, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  self.throttled_responder = lambda do |_request|
    [429, { "Content-Type" => "application/json" }, [{ error: "Too many requests, please try again later" }.to_json]]
  end
end

Rack::Attack.enabled = !Rails.env.test?
