# Model of FileTranscriptPoint
# models/file_transcript_point.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class FileTranscriptPoint < ApplicationRecord
  belongs_to :file_transcript
end
