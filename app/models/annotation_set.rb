# AnnotationSet
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class AnnotationSet < ApplicationRecord
  belongs_to :organization
  belongs_to :collection_resource
  belongs_to :file_transcript
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by', optional: true
  belongs_to :updated_by, class_name: 'User', foreign_key: 'updated_by', optional: true
  has_many :annotations, dependent: :destroy
  validates :title, presence: true
  attr_accessor :dublincore_key, :dublincore_value
end
