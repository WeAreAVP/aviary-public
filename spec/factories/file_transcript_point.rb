FactoryBot.define do
  factory :file_transcript_point do
    sequence(:title) { |n| "Title#{n}" }
    start_time { 6 }
    end_time { 97 }
    duration { 91 }
    sequence(:text) { |n| "text#{n}" }
    sequence(:speaker) { |n| "text#{n}" }
    sequence(:writing_direction) { |n| "text#{n}" }
    association :file_transcript, factory: :file_transcript
  end

  trait :empty_speaker do
    text { 'SPEAKER: Hi' }
    speaker { nil }
  end
end
