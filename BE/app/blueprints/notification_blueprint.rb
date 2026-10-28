class NotificationBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :body, :read, :created_at
end
