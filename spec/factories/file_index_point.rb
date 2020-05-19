FactoryBot.define do
  factory :file_index_point do
    sequence(:title) { |n| "Title#{n}" }
    start_time 6
    end_time 97
    duration 91
    sequence(:synopsis) { |n| "synopsis#{n}" }
    sequence(:partial_script) { |n| "synopsis#{n}" }
    gps_latitude ["32.29838"]
    gps_longitude ["-85.16926"]
    gps_zoom ["15"]
    sequence(:gps_description) { |n| ["gps_description#{n}"] }
    hyperlink ['http://testlink.com']
    sequence(:hyperlink_description) { |n| ["hyperlink_description#{n}"] }
    sequence(:subjects) { |n| "subjects#{n};" }
    sequence(:keywords) { |n| "keywords#{n};" }
    association :file_index, factory: :file_index
  end
end
