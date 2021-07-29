# FileTranscriptPresenter
# presenters/file_transcript_presenter.rb
#
# Use ::Kernel.binding.pry for debug
#
# Author:: Furqan Wasi  (mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class FileTranscriptPresenter < BasePresenter
  delegate :can?, to: :h
  include DetailPageHelper

  def count_annotation_occurrence_present(transcript_id, annotation_count)
    DetailPageHelper.count_annotation_occurrence(transcript_id, annotation_count)
  end
end
