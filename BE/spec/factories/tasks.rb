FactoryBot.define do
  factory :task do
    user
    title { "Send weekly report" }
  end
end
