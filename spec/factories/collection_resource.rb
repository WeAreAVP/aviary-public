FactoryBot.define do
  factory :collection_resource do
    sequence(:title) { |n| "title_#{n}" }
    access { CollectionResource.accesses[:access_public] }
    is_featured { true }
    association :collection, factory: :collection
    trait :not_public do
      access { CollectionResource.accesses[:access_restricted] }
    end

  end
end