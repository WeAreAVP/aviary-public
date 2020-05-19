FactoryBot.define do
  factory :support_request do
    email 'aviary@weareavp.com'
    name { |n| "user name#{n}" }
    request_type :contact_us
    organization { |n| "organization name#{n}" }
    message { |n| "message#{n}" }
  end
end
