FactoryBot.define do
  factory :subscription do
    last_four 'Starter'
    stripe_id 'cust_1234'
    card_type 'visa'
    current_price 9.95
    start_date Time.now
    renewal_date Time.now + 30.days
    association :organization, factory: :organization
    association :plan, factory: :plan
  end
end
