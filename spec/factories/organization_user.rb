FactoryBot.define do
  factory :organization_user do
    status { 1 }
    association :organization, factory: :organization
    association :user, factory: :user
    association :role, factory: :role
  end
end
