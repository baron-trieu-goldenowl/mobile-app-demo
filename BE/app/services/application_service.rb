# Base class for service objects: `SomeService.call(...)`.
class ApplicationService
  def self.call(...)
    new(...).call
  end
end
