require "net/http"

# Minimal JSON-over-HTTPS client for third-party APIs (Google, Apple).
module ExternalHttp
  class Error < StandardError
    attr_reader :status

    def initialize(message, status: nil)
      super(message)
      @status = status
    end
  end

  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 15

  module_function

  def get_json(url, params: {}, headers: {})
    uri = URI(url)
    uri.query = URI.encode_www_form(params) if params.any?
    request = Net::HTTP::Get.new(uri)
    headers.each { |key, value| request[key] = value }
    perform(request)
  end

  def post_form(url, params)
    request = Net::HTTP::Post.new(URI(url))
    request.set_form_data(params)
    perform(request)
  end

  def perform(request)
    uri = request.uri
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                                   open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
      http.request(request)
    end
    body = response.body.present? ? JSON.parse(response.body) : {}
    return body if response.is_a?(Net::HTTPSuccess)

    raise Error.new(error_message(body, response), status: response.code.to_i)
  rescue JSON::ParserError, SocketError, Timeout::Error, SystemCallError, OpenSSL::SSL::SSLError => e
    raise Error, "#{uri.host} request failed: #{e.message}"
  end

  def error_message(body, response)
    return response.message unless body.is_a?(Hash)

    body["error_description"] || body.dig("error", "message") || body["error"] || response.message
  end
end
