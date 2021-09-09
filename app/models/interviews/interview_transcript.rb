# Interviews
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # Interview Transcript
  class InterviewTranscript < ApplicationRecord
    include UserTrackable
    belongs_to :interview
    has_attached_file :associated_file, validate_media_type: false, default_url: ''
    validates_attachment_content_type :associated_file, content_type: ['text/xml', 'application/xml', 'text/vtt', 'text/plain',
                                                                       'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                                                       'application/msword', 'application/zip'],
                                                        message: 'Only XML, WebVTT, TXT, Doc and Docx formats allowed.'
    has_attached_file :translation, validate_media_type: false, default_url: ''
    validates_attachment_content_type :translation, content_type: ['text/xml', 'application/xml', 'text/vtt', 'text/plain',
                                                                   'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                                                   'application/msword', 'application/zip'],
                                                    message: 'Only XML, WebVTT, TXT, Doc and Docx formats allowed.'
  end
end
