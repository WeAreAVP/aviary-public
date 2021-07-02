class AddOhmsSubscriptionToPlans < ActiveRecord::Migration[5.2]
  def change
      Plan.create({ name: 'Aviary OHMS Subscription', stripe_id: 'aviary-ohms-subscription', amount: 0, frequency: 1, max_resources: 10 }) unless Plan.where(name: 'aviary-ohms-subscription').present?
  end
end
