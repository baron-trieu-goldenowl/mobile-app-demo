FactoryBot.define do
  factory :alarm do
    user
    title { "Wake up" }
    time { "06:30" }
    repeat_days { [1, 2, 3, 4, 5] }
  end
end
