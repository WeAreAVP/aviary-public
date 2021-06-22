# services/aviary/youtube_cc.rb
#
# Module Aviary::YoutubeCC
# The module is written to get the youtube close captions
# and store it as transcript
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
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
      languages = list_cc(video_id)
      check_alternative_cc(video_id, resource_file) unless languages.present?
      return unless languages.present?
      languages.each do |language|
        cc_hash = cc_text(video_id, language, resource_file)
        next unless cc_hash.present?
        create_transcript(resource_file, cc_hash, language)
      end
    end

    def list_cc(video_id)
      doc = Nokogiri::XML(open("#{youtube_cc_host}?type=list&v=#{video_id}", read_timeout: 10))
      xml_hash = Hash.from_xml(doc.to_s)
      return false unless xml_hash['transcript_list']['track'].present?
      tracks = xml_hash['transcript_list']['track']
      tracks = [tracks] if tracks.class == Hash
      tracks.map { |track| track['lang_code'] }
    end

    def check_alternative_cc(video_id, resource_file)
      decoded_content = URI.parse("https://youtube.com/get_video_info?video_id=#{video_id}").read.force_encoding('UTF-8')
      content = CGI.unescape(decoded_content)
      regex = /({"captionTracks":.*isTranslatable":(true|false)})/
      match = regex.match(content)
      return unless match.present?
      caption_track = match[0] + ']}'
      tracks = valid_json?(caption_track)
      return unless tracks.present?
      tracks['captionTracks'].each do |track|
        track_uri = CGI.unescape(track['baseUrl'].gsub('u0026', '&'))
        language = track['languageCode']
        cc_hash = cc_text(video_id, language, resource_file, track_uri)
        next unless cc_hash.present?
        create_transcript(resource_file, cc_hash, language)
      end
    rescue StandardError
      'Failed to process'
    end

    def cc_text(video_id, language_code, resource_file, url = nil)
      request_url = url.present? ? url : "#{youtube_cc_host}?lang=#{language_code}&v=#{video_id}"
      doc = Nokogiri::XML(open(request_url, read_timeout: 10))
      return if doc.child.children.count.zero?
      cc_hash = []
      doc.child.children.each_with_index do |text_cc, index|
        start_time = text_cc.attribute('start').value.to_f
        end_time = doc.child.children[index + 1].present? ? doc.child.children[index + 1].attribute('start').value.to_f : resource_file.duration.to_f
        cc_hash << { start_time: start_time,
                     end_time: end_time,
                     duration: end_time - start_time,
                     text: text_cc.children.text }
      end
      cc_hash
    end

    def create_transcript(resource_file, cc_hash, language)
      language_code = languages_array_simple[0][language].present? ? language : 'en'
      language = languages_array_simple[0][language]
      language = language.present? ? language : 'English'
      tmp = Tempfile.new("transcript_#{Time.now.to_i}.vtt")
      file_path = generate_webvtt(cc_hash, tmp)
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
      tmp.close
      file_transcript.file_transcript_points.create(cc_hash)
      collection_resource = CollectionResource.find(resource_file.collection_resource.id)
      collection_resource.reindex_collection_resource
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
