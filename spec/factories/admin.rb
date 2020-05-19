FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@aviaryplatform.com" }
    sequence(:first_name) { |n| "first#{n}" }
    sequence(:last_name) { |n| "last#{n}" }
    sequence(:username) { |n| "username#{n}" }
    password 'password'
    password_confirmation 'password'
    agreement '1'
    preferred_language 'en'
  end
end
