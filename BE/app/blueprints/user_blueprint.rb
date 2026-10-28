class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :name, :created_at
  field :providers
  field :avatar_url
  field(:google_connected) { |user, _options| user.google_connected? }
  field :google_calendar_synced_at
end
