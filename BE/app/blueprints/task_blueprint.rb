class TaskBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :description, :priority, :status,
         :due_at, :reminder_at, :completed_at, :created_at
end
