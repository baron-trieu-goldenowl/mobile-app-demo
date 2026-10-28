FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Minh An" }
    password { "Password1" }
  end
end
