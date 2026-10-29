class NotificationBlueprint < Blueprinter::Base
  identifier :id

  # The app renders known kinds in the user's language from `kind` + `data`;
  # title / body are the English fallback.
  fields :kind, :data, :title, :body, :read, :created_at
end
