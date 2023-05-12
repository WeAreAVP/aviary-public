FactoryBot.define do
  factory :user do
    sequence(:email) {|n| "user#{n}#{Time.new.to_i}@example.com"}
    sequence(:first_name) {|n| "first#{n}"}
    sequence(:last_name) {|n| "last#{n}"}
    sequence(:username) {|n| "username#{n}"}
    password { '1Password@23' }
    password_confirmation { '1Password@23' }
    agreement { '1' }
    confirmed_at { Time.now }
    preferred_language { 'en' }
    created_by_id { 1 }
    updated_by_id { 1 }

    factory :user_as_organization_admin do
      after(:create) do |organization_admin_single|
        create(:organization_user, organization: create(:organization, user: organization_admin_single), user: organization_admin_single, role: create(:role, name: 'Organization Admin', system_name: 'organization_admin'))
      end
    end

    factory :user_as_organization_owner do
      after(:create) do |organization_admin_single|
        create(:organization_user, organization: create(:organization, user: organization_admin_single), user: organization_admin_single, role: create(:role, name: 'Organization Owner', system_name: 'organization_owner'))
      end
    end

    factory :user_as_organization_user do
      after(:create) do |organization_user_single|
        create(:organization_user, organization: create(:organization, user: organization_user_single), user: organization_user_single, role: create(:role, name: 'Organization User', system_name: 'organization_user'))
      end
    end
  end
end
