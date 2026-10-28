class CalendarEventBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :description, :location, :start_at, :end_at, :all_day, :source
end
