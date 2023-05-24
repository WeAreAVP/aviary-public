# JobsDetail
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class JobsDetail < ApplicationRecord
  belongs_to :organization
  has_attached_file :associated_file, validate_media_type: false, default_url: ''
  validates_attachment_content_type :associated_file, content_type: ['application/csv', 'text/csv', 'application/octet-stream', 'text/plain', 'application/vnd.ms-excel', 'text/html'], message: 'Not a valid file format.'
end
