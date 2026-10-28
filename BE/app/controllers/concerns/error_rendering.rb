# Consistent JSON error responses: { "error": "...", "details": {...} }.
module ErrorRendering
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
  end

  private

  def render_error(message, status, details: nil)
    body = { error: message }
    body[:details] = details if details.present?
    render json: body, status: status
  end

  def render_not_found
    render_error("Not found", :not_found)
  end

  def render_record_invalid(exception)
    record = exception.record
    render_error(record.errors.full_messages.to_sentence, :unprocessable_content, details: record.errors.to_hash)
  end

  def render_bad_request(exception)
    render_error(exception.message, :bad_request)
  end
end
