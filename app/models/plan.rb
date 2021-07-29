# Model of Plan
# models/plan.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Plan < ApplicationRecord
  has_many :subscriptions
  scope :monthly, -> { where(frequency: Frequency::MONTHLY).where.not(stripe_id: pay_a_y_go) }
  scope :yearly, -> { where(frequency: Frequency::YEARLY) }
  scope :pay_as_you_go, -> { where(stripe_id: pay_a_y_go) }
  scope :admin_packages, -> { where('frequency != ?', Frequency::FOREVER) }
  # Frequency Class
  class Frequency
    MONTHLY = 1
    YEARLY = 2
    FOREVER = 3
    NAMES = { MONTHLY => 'Monthly', YEARLY => 'Yearly', FOREVER => 'Enterprise' }.freeze

    def self.for_select
      NAMES.invert.to_a[0..1]
    end

    def self.name(frequency)
      NAMES[frequency]
    end
  end

  def self.frequency(frequency)
    Frequency.name(frequency)
  end

  def package
    "#{name} - #{Frequency.name(frequency)}"
  end

  def self.pay_a_y_go
    'aviary-pay-as-you-go'
  end
end
