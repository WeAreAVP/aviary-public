FactoryBot.define do
  factory :file_index_point do
    sequence(:title) { |n| "Title#{n}" }
    start_time { 6 }
    end_time { 97 }
    duration { 91 }
    sequence(:synopsis) { |n| "synopsis#{n}" }
    sequence(:partial_script) { |n| "partial_script#{n}" }
    sequence(:publisher) { |n| "publisher#{n}1:::First Term|||publisher#{n}2:::Second Term" }
    sequence(:contributor) { |n| "contributor#{n}1:::Third Term|||contributor#{n}2:::Fourth Term" }
    sequence(:identifier) { |n| "identifier#{n}1:::Fifth Term|||identifier#{n}2:::Sixth Term" }
    sequence(:segment_date) { |n| "segment_date#{n}1:::Seventh Term|||segment_date#{n}2:::Eighth Term" }
    sequence(:rights) { |n| "rights#{n}1:::Ninth Term|||rights#{n}2:::Tenth Term" }
    gps_latitude { ["32.29838"] }
    gps_longitude { ["-85.16926"] }
    gps_zoom { ["15"] }
    sequence(:gps_description) { |n| ["gps_description#{n}"] }
    hyperlink { ['http://testlink.com'] }
    sequence(:hyperlink_description) { |n| ["hyperlink_description#{n}"] }
    sequence(:subjects) { |n| "subjects#{n};" }
    sequence(:keywords) { |n| "keywords#{n};" }
    association :file_index, factory: :file_index
  end
end
