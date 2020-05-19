FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization_name_#{n}" }
    sequence(:url) { |n| "customurl#{n}" }
    sequence(:description) { |n| "Organization_description_#{n}" }
    sequence(:address_line_1) { |n| "Organization_address_line_1_#{n}" }
    sequence(:city) { |n| "Organization_city_#{n}" }
    sequence(:state) { |n| "Organization_state_#{n}" }
    sequence(:country) { |n| "Organization_country_#{n}" }
    sequence(:zip) { |n| "Organization_zip_#{n}" }
    logo_image { File.new("#{Rails.root}/spec/fixtures/abc.png") }
    banner_image { File.new("#{Rails.root}/spec/fixtures/abc.png") }
    bucket_name { |n| "custom-url-#{n}" }
    banner_slider_resources { |n| "{id:1}" }
    storage_type 2
    association :user, factory: :user


    after(:create) do |organization|
      role = Role.where(:system_name => 'organization_owner').first || create(:role_organization_owner)
      organization.organization_users.create(user_id: organization.user.id, role_id: role.id)
    end
    factory :organization_with_collection do
      after(:create) do |organization_with_collection_single|
        create(:collection, organization: organization_with_collection_single)
        create(:collection, organization: organization_with_collection_single)
      end
    end
  end

  def get_owner(name)
    # get existing group or create new one

  end
end
