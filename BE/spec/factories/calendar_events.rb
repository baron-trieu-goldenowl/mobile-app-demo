FactoryBot.define do
  factory :calendar_event do
    user
    title { "Standup" }
    start_at { 1.day.from_now }
    end_at { 1.day.from_now + 30.minutes }
    source { "local" }

    trait :google do
      source { "google_calendar" }
      sequence(:external_id) { |n| "google-#{n}" }
    end
  end
end
