# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # NoteController
  class NotesController < ApplicationController
    before_action :authenticate_user!
    # GET /interview/notes
    # GET /interview/notes.json
    def index
      authorize! :manage, Interviews::Interview
      interview = Interview.find(params[:id])
      respond_to do |format|
        format.html
        format.json { render json: { data: interview.interview_notes, color: color(interview) } }
      end
    end

    # POST /interview/notes
    # POST /interview/notes.json
    def create
      authorize! :manage, Interviews::Interview
      interview = Interview.find(params[:id])
      interview_notes = InterviewNote.new
      interview_notes.interview = interview
      interview_notes.note = params[:note]
      interview_notes.inject_created_by(current_user)
      interview_notes.inject_updated_by(current_user)
      if !interview_notes.validate
        respond_to do |format|
          format.html
          format.json { render json: { errors: interview_notes.errors, color: color(interview) }, status: :bad_request unless interview_notes.validate }
        end
      else
        interview_notes.save
        interview.reindex
        respond_to do |format|
          format.html
          format.json { render json: { data: interview.interview_notes, color: color(interview) } }
        end
      end
    end

    # POST /interview/note/update
    # POST /interview/note/update.json
    def update
      authorize! :manage, Interviews::Interview
      interview_notes = InterviewNote.find(params[:note_id])
      interview_notes.status = (params[:status].to_i == 1)
      interview_notes.inject_updated_by(current_user)
      interview_notes.save
      interview = Interview.find(interview_notes.interview_id)
      interview.reindex
      respond_to do |format|
        format.html
        format.json { render json: { data: interview_notes, color: color(interview) } }
      end
    end

    private

    def color(interview)
      if interview.interview_notes.length.positive?
        interview.interview_notes.where(status: false).count.positive? ? 'text-danger' : 'text-success'
      else
        'text-secondary'
      end
    end
  end
end
