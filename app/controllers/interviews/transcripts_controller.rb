# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # TranscriptsController
  class TranscriptsController < ApplicationController
    before_action :authenticate_user!

    def create
      authorize! :manage, current_organization
      interview = Interviews::Interview.find(params[:id])
      if params['interview_transcript'].present?
        if interview.interview_transcript.present?
          interview_transcript = interview.interview_transcript
          interview_transcript.update(interview_transcript_params)
        else
          interview_transcript = Interviews::InterviewTranscript.new(interview_transcript_params)
          interview_transcript.inject_created_by(current_user)
          interview_transcript.interview = interview
        end
        interview_transcript.inject_updated_by(current_user)
        flash[:notice] = interview_transcript.save ? 'Interview Transcript Created Successfully.' : t('error_update')
      else
        interview_transcript = interview.interview_transcript
      end
      respond_to do |format|
        format.json { render json: { response: interview_transcript.present? ? interview_transcript : '' } }
        format.html { redirect_back(fallback_location: root_path) }
      end
    end

    private

    def interview_transcript_params
      params.require(:interview_transcript).permit(:associated_file, :translation, :no_transcript, :timecode_intervals)
    end
  end
end
