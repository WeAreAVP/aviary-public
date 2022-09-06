FactoryBot.define do
  factory :fields, class: CustomFields::Field do
    sequence(:label) { |n| "label_#{n}" }
    sequence(:system_name) { |n| "system_name_#{n}" }
    sequence(:is_vocabulary) { |n| 0 }
    sequence(:column_type) { |n| 4 }
    sequence(:default) { |n| 1 }
    sequence(:help_text) { |n| "help_text_#{n}" }
    sequence(:is_custom) { |n| 1 }
    is_public { 1 }
    is_repeatable { 0 }
    is_required { 0 }
    source_type { 'CollectionResource' }
    trait :is_dropdown do
      dropdown_options { %w[opt1 opt2 opt3] }
      column_type { 1 }
    end

    trait :has_vocabulary do
      is_vocabulary { 1 }
      vocabulary { %w[vocab1 vocab2 vocab3] }
    end
  end
end
