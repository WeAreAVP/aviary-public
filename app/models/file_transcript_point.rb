# Model of FileTranscriptPoint
# models/file_transcript_point.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class FileTranscriptPoint < ApplicationRecord
  belongs_to :file_transcript
end
