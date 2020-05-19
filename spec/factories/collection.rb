FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "title_#{n}" }
    sequence(:about) { |n| "about_#{n}" }
    image { File.new("#{Rails.root}/spec/fixtures/abc.png") }
    is_public true
    is_featured true
    association :organization, factory: :organization


    factory :collection_with_multiple_files do
      after(:create) do |single_collection|
        create(:collection_resource, collection: single_collection)
        create(:collection_resource, collection: single_collection)
        create(:collection_resource, collection: single_collection)
        create(:collection_resource, collection: single_collection)
      end
    end
  end
end
