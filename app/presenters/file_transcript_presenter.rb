# FileTranscriptPresenter
# presenters/file_transcript_presenter.rb
#
# Use ::Kernel.binding.pry for debug
#
# Author:: Furqan Wasi  (mailto:furqan@weareavp.com)
class FileTranscriptPresenter < BasePresenter
  delegate :can?, to: :h
  include DetailPageHelper

  def count_annotation_occurrence_present(transcript_id, annotation_count)
    DetailPageHelper.count_annotation_occurrence(transcript_id, annotation_count)
  end
end
