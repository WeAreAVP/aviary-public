FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role_#{n}" }
    sequence(:system_name) { |n| "Role_#{n}" }
    factory :role_organization_owner, :parent => :role do
      name "Organization Owner"
      system_name "organization_owner"
    end
    factory :role_organization_admin, :parent => :role do
      name "Organization Admin"
      system_name "organization_admin"
    end
    factory :role_organization_user, :parent => :role do
      name "Organization User"
      system_name "organization_user"
    end
  end
end
