# The mobile app does not need CORS. Allow browser origins only when
# explicitly configured, e.g. CORS_ORIGINS="https://admin.dayflow.app".
origins = ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).compact_blank

if origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*origins)
      resource "/api/*",
               headers: :any,
               methods: %i[get post put patch delete options head]
    end
  end
end
