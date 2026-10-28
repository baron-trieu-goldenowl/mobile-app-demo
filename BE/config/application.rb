require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Be
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.api_only = true
    config.time_zone = "UTC"

    # OAuth refresh tokens are encrypted at rest. Keys come from the
    # environment in production (generate with `bin/rails db:encryption:init`).
    config.active_record.encryption.tap do |encryption|
      fallback = ->(name) { Rails.env.production? ? raise("#{name} is not set") : "insecure-dev-#{name.downcase}" }
      encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY") { fallback.call("AR_ENCRYPTION_PRIMARY_KEY") }
      encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY") do
        fallback.call("AR_ENCRYPTION_DETERMINISTIC_KEY")
      end
      encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT") do
        fallback.call("AR_ENCRYPTION_KEY_DERIVATION_SALT")
      end
    end

    config.middleware.use Rack::Attack

    config.generators do |g|
      g.test_framework :rspec
      g.factory_bot dir: "spec/factories"
    end
  end
end
