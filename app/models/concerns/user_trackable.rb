# (concern) e.g. for Thesaurus::Thesaurus model
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module UserTrackable
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
    belongs_to :updated_by, class_name: 'User', foreign_key: 'updated_by_id'

    scope :created_by, ->(user) { where(created_by_id: user.id) }
    scope :updated_by, ->(user) { where(updated_by_id: user.id) }
  end

  def inject_created_by(user)
    self.created_by = user
    true
  end

  def inject_updated_by(user)
    self.updated_by = user
    true
  end
end
