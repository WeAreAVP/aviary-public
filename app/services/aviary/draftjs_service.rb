# services/aviary/draftjs_service.rb
#
# Module Aviary::DraftjsService
# The class is written to convert the draftjs json to transcript points and webvvt file
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # The class is written to convert the draftjs json to transcript points and webvvt file
  class DraftjsService
    include DeprecatedHelper
    def create_transcript_points(transcript)
      slate_js_blocks = JSON.parse(transcript.slate_js)
      transcript_point_hash = []

      words = slate_js_blocks[0]['children'][0]['words']
      slate_js_blocks.each_with_index do |point, idx|
        data = point['children'][0]
        text = data['text']
        paragraph_words = text.split(' ')
        speaker = point['speaker'].present? && point['speaker'].downcase != 'add speaker' ? point['speaker'] : ''
        word_timestamp = []

        paragraph_words.each do |word|
          start_time = point['start']
          end_time = slate_js_blocks.length >= idx + 1 && slate_js_blocks[idx + 1] ? slate_js_blocks[idx + 1]['start'] : words.last['end']
          word_timestamp << {
            start: start_time,
            end: end_time,
            speaker: speaker,
            text: word
          }
        end

        start_time = word_timestamp.first[:start]
        end_time = word_timestamp.last[:end]
        duration = end_time - start_time
        single_hash = {}
        single_hash['text'] = text
        single_hash['speaker'] = speaker
        single_hash['start_time'] = start_time
        single_hash['end_time'] = end_time
        single_hash['duration'] = duration
        single_hash['word_timestamp'] = word_timestamp
        transcript_point_hash << single_hash
      end
      transcript_point_hash
      FileTranscriptPoint.transaction do
        Aviary::IndexTranscriptManager::TranscriptManager.new.update_existing_points(transcript, transcript_point_hash)
      end
    end

    def create_webvtt(transcript)
      tmp = Tempfile.new("transcript_#{Time.now.to_i}.vtt")
      draft_js = JSON.parse(transcript.slate_js)
      file_path = generate_webvtt(draft_js, tmp)
      transcript.associated_file = open(file_path)
      transcript.save
      tmp.close
    end

    def generate_webvtt(points, tmp_file)
      timestamp_words = points[0]['children'][0]['words']
      webvtt_timestamp = ''
      webvtt_text = "WEBVTT\n\n"
      words = []
      timestamp_words.each do |timestamp_word|
        webvtt_timestamp = timestamp_word['start'] if webvtt_timestamp.blank?
        words << timestamp_word['text']
        if timestamp_word['end'] - webvtt_timestamp >= 4 || (webvtt_timestamp.present? && timestamp_word.equal?(timestamp_words.last))
          webvtt_text += "#{Time.at(webvtt_timestamp).utc.strftime('%H:%M:%S.%L')} --> #{Time.at(timestamp_word['end']).utc.strftime('%H:%M:%S.%L')}\n"
          webvtt_text += "#{words.join(' ')}\n\n"
          webvtt_timestamp = ''
          words = []
        end
      end
      tmp_file << webvtt_text
      tmp_file.flush
      tmp_file.path
    end
  end
end
