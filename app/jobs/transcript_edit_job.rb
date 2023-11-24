# app/jobs/transcript_edit_job.rb
#
# The job will run in the background and tranascode the video file that is larger then the 2 GB
#
# Author::    Fayzan Wasim  (mailto:fayzan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class TranscriptEditJob < ApplicationJob
  queue_as :transcript_editor

  def perform(payload)
    update_transcript(payload)
    draft_js_service = Aviary::DraftjsService.new
    draft_js_service.create_transcript_points(payload[:transcript])
    draft_js_service.create_webvtt(payload[:transcript])
  end

  private

  def create_slate_file(slatejs)
    tmp = Tempfile.new("slate_js#{Time.now.to_i}.json")
    tmp << slatejs
    tmp.flush
    tmp.path
  end

  def update_transcript(payload)
    transcript = payload[:transcript]
    file_path = create_slate_file(payload[:params]['slatejs'].to_json)
    transcript.saved_slate_js = open(file_path)
    transcript.save
    transcript.update(is_edit: payload[:params]['is_edit'], user_id: payload[:current_user_id], title: payload[:params]['title'])
  end
end
