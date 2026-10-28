Blueprinter.configure do |config|
  config.datetime_format = ->(datetime) { datetime&.utc&.iso8601(3) }
  config.sort_fields_by = :definition
end
