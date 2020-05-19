FactoryBot.define do
  factory :file_index do
    sequence(:title) { |n| "Title#{n}" }
    sequence(:language) { |n| "language#{n}" }
    sequence(:is_public) { |n| 0 }
    sequence(:sort_order) { |n| 1 }
    associated_file { File.new("#{Rails.root}/spec/fixtures/valid_sample_xml.xml") }
    association :user, factory: :user
    association :collection_resource_file, factory: :collection_resource_file

    trait :invalid do
      associated_file File.new("#{Rails.root}/spec/fixtures/invalid_sample_xml.xml")
      title nil
    end

    trait :invalid_webvtt do
      associated_file File.new("#{Rails.root}/spec/fixtures/webvtt-invalid.webvtt")
      title nil
    end

    trait :use_webvtt do
      associated_file File.new("#{Rails.root}/spec/fixtures/webvtt-valid.webvtt")
    end

    trait :use_webvtt_missing do
      associated_file File.new("#{Rails.root}/spec/fixtures/webvtt-missing.webvtt")
    end
    trait :use_webvtt_missing_time do
      associated_file File.new("#{Rails.root}/spec/fixtures/webvtt-missing-timestamp.webvtt")
    end

    trait :use_ohms_missing do
      associated_file File.new("#{Rails.root}/spec/fixtures/valid_sample_missing.xml")
    end
    trait :use_ohms_index_alt do
      associated_file File.new("#{Rails.root}/spec/fixtures/OHMS-Sample-006.xml")
    end

  end
end
