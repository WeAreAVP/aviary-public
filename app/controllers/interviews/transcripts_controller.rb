# frozen_string_literal: true

#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
  # TranscriptsController
  class TranscriptsController < ApplicationController
    before_action :authenticate_user!

    def edit
      @file_transcript = FileTranscript.find(params[:id])
      if request.patch? && params['file_transcript'].present? && params['file_transcript']['text'].present?
        time = 0.0
        time_different = @file_transcript.timecode_intervals.to_f * 60

        params['file_transcript']['text'] = params['file_transcript']['text'].gsub("\r", '')
        transcript_manager = Aviary::OhmsTranscriptManager.new
        params['file_transcript']['text'] = transcript_manager.parse_notes_info(params['file_transcript']['text'], @file_transcript)

        @text = params['file_transcript']['text']
        raw_point = @text.split("\n")
        @file_transcript.file_transcript_points.each do |single_transcript_point|
          single = single_transcript_point.point_info.split('(')
          row = single[0].to_i
          column = single[1].to_i
          if row > 0 && column > 0
            time += time_different
            if raw_point[row][column] != ' '
              start = 1
              found = false
              if raw_point[row].length > column
                found, column, start = find_forward(found, start, raw_point, row, column)
                if raw_point[row][column] != ' '
                  _found, column, _start = find_backward(found, start, raw_point, row, column)
                end
              else
                found, column, start = find_backward(found, start, raw_point, row, column)
                if raw_point[row][column] != ' '
                  _found, column, _start = find_forward(found, start, raw_point, row, column)
                end
              end
            end
            raw_point[row].insert(column, " [#{Time.at(time).utc.strftime('%H:%M:%S')}] ")
          end
        end
        @text = raw_point.join("\n")
        main_transcript = Sanitize.fragment(@text)
        file = Tempfile.new('content')
        file.path
        file.write(main_transcript)
        transcript_manager = Aviary::OhmsTranscriptManager.new
        transcript_manager.sync_interval = @file_transcript.timecode_intervals.to_f
        transcript_manager.from_resource_file = false
        hash = transcript_manager.parse_text(main_transcript, @file_transcript)
        transcript_manager.map_hash_to_db(@file_transcript, hash, false)
        file.close
        file.unlink
      end
      @text = @file_transcript.file_transcript_points.pluck(:text).join(' ')
      transcript_manager = Aviary::OhmsTranscriptManager.new
      @text =  transcript_manager.read_notes_info(@file_transcript, @text)
      OhmsBreadcrumbPresenter.new(@file_transcript, view_context).breadcrumb_manager('edit', @file_transcript, 'sync')
    end

    def create
      authorize! :manage, current_organization
      interview = Interviews::Interview.find(params[:id])
      message = ''
      response = if params['interview_transcript'].present?
                   if params['interview_transcript']['associated_file'].present? || params['interview_transcript']['translation'].present?
                     error_main_transcript = validate_transcript(params['interview_transcript']['associated_file'], params['interview_transcript']['timecode_intervals'])
                     if error_main_transcript == 0 && params[:interview_transcript][:associated_file].present?
                       interview_transcript = upload_transcript('main', params[:interview_transcript][:associated_file], interview)
                       if interview_transcript.present? && interview_transcript.save
                         begin
                           remove_title = ''
                           is_new = true
                           transcript_manager = Aviary::OhmsTranscriptManager.new
                           transcript_manager.from_resource_file = false
                           transcript_manager.sync_interval = params['interview_transcript']['timecode_intervals'].to_f
                           transcript_manager.process(interview_transcript, remove_title, is_new)
                           message = if interview_transcript.save
                                       "Interview Transcript #{params['interview_transcript']['associated_file'].present? ? 'Translation' : ''} Created Successfully."
                                     else
                                       t('error_update')
                                     end
                         rescue StandardError => ex
                           Rails.logger.error ex
                         end
                       end
                       message = ' Transcript information updated successfully '
                     end
                     error_translation_transcript = validate_transcript(params['interview_transcript']['translation'], params['interview_transcript']['timecode_intervals'])
                     if error_translation_transcript == 0 && params[:interview_transcript][:translation].present?
                       interview_transcript_translation = upload_transcript('translation', params[:interview_transcript][:translation], interview)
                       if interview_transcript_translation.present? && interview_transcript_translation.save
                         begin
                           remove_title = ''
                           is_new = true
                           transcript_manager = Aviary::OhmsTranscriptManager.new
                           transcript_manager.from_resource_file = false
                           transcript_manager.process(interview_transcript_translation, remove_title, is_new)
                         rescue StandardError => ex
                           Rails.logger.error ex
                         end
                       end
                       message = ' Transcript information updated successfully '
                     end
                   end

                   param = {}
                   if error_translation_transcript == 1 || error_main_transcript == 1
                     message = 'The format of the timecodes is invalid. Please upload a file with 30 seconds, 1, 2, 3, 4, or 5 minutes intervals. Only one time interval type is allowed per file.'
                     param = { interview_transcript_id: interview.id, e: error_translation_transcript == 1 || error_main_transcript == 1 }
                     flash[:error] = message
                   else
                     if interview.present?
                       interview.file_transcripts.update(JSON.parse(params['interview_transcript'].to_json).except!('translation', 'associated_file'))
                       message = ' Transcript information updated successfully '
                     end
                     flash[:notice] = message
                   end
                 else
                   [interview.file_transcripts.where(interview_transcript_type: 'main').try(:first), interview.file_transcripts.where(interview_transcript_type: 'translation').try(:first)]
                 end
      respond_to do |format|
        format.json { render json: { response: response } }
        format.html { redirect_to ohms_records_path(param) }
      end
    end

    def change_sync_interval
      translation_transcript_text = ''
      main_transcript_text = ''
      interview = Interviews::Interview.find(params[:id])
      timecode = params['timecode']
      main = interview.file_transcripts.where(interview_transcript_type: 'main').try(:first)
      translation = interview.file_transcripts.where(interview_transcript_type: 'translation').try(:first)

      if main.present?
        main.timecode_intervals = timecode
        main.save
      end

      if translation.present?
        translation.timecode_intervals = timecode
        translation.save
      end

      if main.present? && main.file_transcript_points.present?
        main.file_transcript_points.each do |single_transcript_point|
          main_transcript_text += ' ' + single_transcript_point.text + ' '
        end
      end

      if translation.present? && translation.file_transcript_points.present?
        translation.file_transcript_points.each do |single_transcript_point|
          translation_transcript_text += ' ' + single_transcript_point.text + ' '
        end
      end

      if main_transcript_text.present?
        file_transcripts_update = interview.file_transcripts.where(interview_transcript_type: 'main').try(:first)
        content_manage(main_transcript_text, file_transcripts_update) if file_transcripts_update.present?
      end

      if translation_transcript_text.present?
        file_transcripts_update = interview.file_transcripts.where(interview_transcript_type: 'translation').try(:first)
        content_manage(translation_transcript_text, file_transcripts_update) if file_transcripts_update.present?
      end

      respond_to do |format|
        format.html { redirect_to sync_interviews_manager_path(interview.id), notice: t('updated_successfully') }
      end
    end

    private

    def find_forward(found, start, raw_point, row, column)
      while found == false
        found = true if raw_point[row][column + start].nil?
        if raw_point[row][column + start] == ' '
          found = true
          column += start
        end
        start += 1
      end
      [found, column, start]
    end

    def find_backward(found, start, raw_point, row, column)
      while found == false
        if raw_point[row][column - start] == ' '
          found = true
          column += start
        end
        start += 1
      end
      [found, column, start]
    end

    def content_manage(translation_transcript_text, file_transcripts_update)
      main_transcript = Sanitize.fragment(translation_transcript_text)
      file = Tempfile.new('content')
      file.path
      file.write(translation_transcript_text)
      transcript_manager = Aviary::OhmsTranscriptManager.new
      transcript_manager.from_resource_file = false
      hash = transcript_manager.parse_text(main_transcript, file_transcripts_update)
      transcript_manager.map_hash_to_db(file_transcripts_update, hash, false)
      file.close
      file.unlink
    end

    def upload_transcript(type, file, interview)
      interview.file_transcripts.where(interview_transcript_type: type).destroy_all if interview.file_transcripts.where(interview_transcript_type: type).present?
      interview_transcript_translation = FileTranscript.new({ collection_resource_file_id: nil, user: current_user,
                                                              title: file.original_filename, interview: interview,
                                                              language: 'en', is_public: false, sort_order: 0, associated_file: file,
                                                              is_caption: false, auto_service_id: nil, interview_transcript_type: type })
      interview_transcript_translation
    end

    def validate_transcript(transcript, timecode_intervals)
      error_translation_transcript = 0
      if transcript.present?
        file = transcript.tempfile.read
        matches = file.scan(/\[(?:[01]\d|2[0123]):(?:[012345]\d):(?:[012345]\d)\]/)
        sync_interval = timecode_intervals.to_f
        if sync_interval.to_f < 1
          interval_t = 30
          'sec'
        else
          interval_t = sync_interval.to_f * 60
          'min'
        end

        last_diff_time = 0
        if matches.present?
          matches.each do |single_slot|
            if single_slot.present?
              single_slot_seconds_t = single_slot.split(':').map(&:to_i).inject(0) { |a, b| a * 60 + b }
              if single_slot_seconds_t > 0 && (single_slot_seconds_t - last_diff_time) != interval_t
                error_translation_transcript = 1
              end
              last_diff_time = single_slot_seconds_t
            end
          end
        end
      end

      error_translation_transcript
    end

    def interview_transcript_params
      params.require(:interview_transcript).permit(:associated_file, :translation, :no_transcript, :timecode_intervals)
    end
  end
end
