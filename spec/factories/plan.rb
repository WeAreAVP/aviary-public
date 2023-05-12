FactoryBot.define do
  factory :plan do
    name { 'Starter' }
    stripe_id { 7.46 }
    amount { 71.64 }
    frequency { 1 }
    max_resources { 100 }
    trait :yearly do
      frequency { 2 }
    end
  end
end
