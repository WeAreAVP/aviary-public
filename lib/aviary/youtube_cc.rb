# services/aviary/youtube_cc.rb
#
# Module Aviary::YoutubeCC
# The module is written to get the youtube close captions
# and store it as transcript
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # YoutubeCC Class to check the close caption against youtube video and extract and store it
  class YoutubeCC
    include ApplicationHelper
    mattr_accessor :youtube_cc_host

    def initialize
      self.youtube_cc_host = 'https://www.youtube.com/api/timedtext'
    end

    def check_and_extract(resource_file)
      video_id = resource_file.embed_code.split('?v=').last
      languages = nil
      check_alternative_cc(video_id, resource_file) unless languages.present?
      nil unless languages.present?
    end

    def check_alternative_cc(video_id, resource_file)
      path = Rails.root.join('bin', 'youtube-dl').to_s
      output_path = Rails.root.join('tmp', 'youtube-dl', video_id + '/').to_s
      system(path + ' --write-auto-sub --skip-download --output "' + output_path + video_id + '" https://www.youtube.com/watch\?v\=' + video_id)
      files = Dir[output_path + '*']
      files.each do |file|
        file_segments = file.split('.')
        language = file_segments[file_segments.size - 2] || nil
        language ? create_transcript(resource_file, '', language, file) : nil
        FileUtils.rm_rf(output_path)
      end
    rescue StandardError
      'Failed to process'
    end

    def create_transcript(resource_file, cc_hash, language, file = '')
      if file.empty?
        language_code = languages_array_simple[0][language].present? ? language : 'en'
        language = languages_array_simple[0][language]
        language = language.present? ? language : 'English'
        tmp = Tempfile.new("transcript_#{Time.now.to_i}.vtt")
        file_path = generate_webvtt(cc_hash, tmp)
      else
        language_code = language
        file_path = file
      end
      file_transcript = FileTranscript.new
      file_transcript.collection_resource_file = resource_file
      file_transcript.user = resource_file.collection_resource.collection.organization.user
      file_transcript.title = "YouTube #{language}"
      file_transcript.language = language_code
      file_transcript.is_public = false
      file_transcript.sort_order = resource_file.file_transcripts.count + 1
      file_transcript.associated_file = open(file_path)
      file_transcript.is_caption = false
      file_transcript.save
      if file.empty?
        tmp.close
        file_transcript.file_transcript_points.create(cc_hash)
      else
        Aviary::IndexTranscriptManager::TranscriptManager.new.process(file_transcript)
      end
      collection_resource = CollectionResource.find(resource_file.collection_resource.id)
      collection_resource.reindex_collection_resource
    rescue StandardError
      'Failed to process'
    end

    def generate_webvtt(cc_hash, tmp_file)
      webvtt_text = "WEBVTT\n\n"
      cc_hash.each do |single|
        webvtt_text += "#{Time.at(single[:start_time]).utc.strftime('%H:%M:%S.%L')} --> #{Time.at(single[:end_time]).utc.strftime('%H:%M:%S.%L')}\n"
        webvtt_text += "#{single[:text]} \n\n"
      end
      tmp_file << webvtt_text
      tmp_file.flush
      tmp_file.path
    end
  end
end
