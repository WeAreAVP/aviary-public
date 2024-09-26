# Annotation
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Annotation < ApplicationRecord
  belongs_to :annotation_set
  attribute :motivation, :integer
  attribute :body_type, :integer
  attribute :target_type, :integer
  attribute :target_content, :integer
  enum motivation: %i[assessing bookmarking classifying commenting describing editing highlighting identifying linking moderating questioning replying tagging]

  enum body_type: { audio: 0, image: 1, text: 2, video: 3 }, _prefix: :body
  enum target_type: { audio: 0, image: 1, text: 2, video: 3 }, _prefix: :target
  enum target_content: { FileTranscript: 0, FileIndex: 1, CollectionResourceFile: 2 }
end
