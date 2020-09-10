# services/aviary/index_transcript_manager.rb
#
# Module Aviary::IndexTranscriptManager
# The module is written to store the index and transcript for the collection resource file
# Currently supports OHMS XML and WebVtt format
# Nokogiri, webvtt-ruby gem is needed to run this module successfully
# dry-transaction gem is needed for adding transcript steps to this process
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
module Aviary::IndexTranscriptManager
  POINTS_PER_PAGE = 4000.to_f
  # IndexManager Class for managing the index import of OHMS and WebVTT files
  class IndexManager
    include Dry::Transaction
    include ApplicationHelper
    step :process
    try :parse_webvtt
    try :parse_ohms_xml
    step :map_hash_to_db

    def process(file_index)
      file_path = ENV['RAILS_ENV'] == 'production' ? file_index.associated_file.url : file_index.associated_file.path
      if ['application/xml', 'text/xml'].include? file_index.associated_file_content_type
        doc = Nokogiri::XML(open(file_path))
        xml_hash = Hash.from_xml(doc.to_s)
        hash, alt_hash, language = parse_ohms_xml(xml_hash, file_index)
        map_hash_to_db(file_index, hash, alt_hash, language)
      else
        require 'webvtt'
        tmp = Tempfile.new("webvtt_#{Time.now.to_i}")
        if ENV['RAILS_ENV'] == 'production'
          tmp << URI.parse(file_path).read.force_encoding('UTF-8')
          tmp.flush
          file_path = tmp.path
        end
        webvtt = WebVTT.read(file_path)
        tmp.close
        hash = parse_webvtt(webvtt)
        map_hash_to_db(file_index, hash)
      end
    end

    def parse_webvtt(webvtt)
      index_hash = []
      webvtt.cues.each do |cue|
        single_hash = {}
        single_hash['title'] = cue.identifier.present? ? cue.identifier : index_hash.size + 1
        single_hash['start_time'] = cue.start.to_f
        single_hash['end_time'] = cue.start.to_f
        single_hash['duration'] = single_hash['end_time'] - single_hash['start_time']
        single_hash['synopsis'] = cue.text.present? ? cue.text.gsub(%r{/<\/?[^>]*>}, '') : ''
        index_hash << single_hash
      end
      index_hash
    end

    def parse_index(index_points, file_index, alt_tag = '')
      index_hash = []
      index_points = [index_points] unless index_points[0].present?
      index_points.each_with_index do |single_point, index|
        single_hash = {}
        gps_info = { gps_latitude: [], gps_longitude: [], gps_zoom: [], gps_description: [] }
        hyperlink_info = { hyperlink: [], hyperlink_description: [] }
        if single_point['gpspoints'].present?
          gps_points = single_point['gpspoints']
          gps_points = [gps_points] if gps_points.class == Hash
          gps_points.each do |gps_point|
            gps_info = get_gps_points(gps_point, alt_tag, gps_info)
          end
        elsif single_point['gps'].present?
          gps_info = get_gps_points(single_point, alt_tag, gps_info)
        end
        single_hash['gps_latitude'] = gps_info[:gps_latitude].to_json
        single_hash['gps_longitude'] = gps_info[:gps_longitude].to_json
        single_hash['gps_zoom'] = gps_info[:gps_zoom].to_json
        single_hash['gps_description'] = gps_info[:gps_description].to_json
        if single_point['hyperlinks'].present?
          hyperlinks = single_point['hyperlinks']
          hyperlinks = [hyperlinks] if hyperlinks.class == Hash
          hyperlinks.each do |hyperlink|
            hyperlink_info = get_hyperlinks(hyperlink, alt_tag, hyperlink_info)
          end
        else
          hyperlink_info = get_hyperlinks(single_point, alt_tag, hyperlink_info)
        end
        single_hash['hyperlink'] = hyperlink_info[:hyperlink].to_json
        single_hash['hyperlink_description'] = hyperlink_info[:hyperlink_description].to_json

        single_hash['title'] = single_point["title#{alt_tag}"]
        single_hash['start_time'] = single_point['time']
        single_hash['synopsis'] = single_point["synopsis#{alt_tag}"]
        single_hash['partial_script'] = single_point["partial_transcript#{alt_tag}"]
        single_hash['subjects'] = single_point["subjects#{alt_tag}"]
        single_hash['keywords'] = single_point["keywords#{alt_tag}"]
        single_hash['end_time'] = if index_points[index + 1].present?
                                    index_points[index + 1]['time']
                                  else
                                    file_index.collection_resource_file.duration
                                  end
        single_hash['duration'] = single_hash['end_time'].to_f - single_hash['start_time'].to_f
        index_hash << single_hash unless single_hash['title'].blank?
      end
      index_hash
    end

    def get_hyperlinks(xml_tag, alt_tag, hyperlink_info)
      if xml_tag['hyperlink'].present?
        hyperlink_info[:hyperlink] << xml_tag['hyperlink']
        description = xml_tag["hyperlink_text#{alt_tag}"].present? ? xml_tag["hyperlink_text#{alt_tag}"] : ''
        hyperlink_info[:hyperlink_description] << description
      end
      hyperlink_info
    end

    def get_gps_points(xml_tag, alt_tag, gps_info)
      if xml_tag['gps'].present? && xml_tag['gps'].split(/, */).length == 2
        gps_points = xml_tag['gps'].split(/, */)
        if gps_points[0].present? && gps_points[1].present?
          gps_info[:gps_latitude] << gps_points[0]
          gps_info[:gps_longitude] << gps_points[1]
          zoom = xml_tag['gps_zoom'].present? ? xml_tag['gps_zoom'] : ''
          description = xml_tag["gps_text#{alt_tag}"].present? ? xml_tag["gps_text#{alt_tag}"] : ''
          gps_info[:gps_zoom] << zoom
          gps_info[:gps_description] << description
        end
      end
      gps_info
    end

    def parse_ohms_xml(xml_hash, file_index)
      index_points = xml_hash['ROOT']['record']['index']['point']
      hash = parse_index(index_points, file_index)
      translate = xml_hash['ROOT']['record']['translate']
      alt_hash = language = nil
      if translate.to_i == 1
        language = languages_array_simple[0].key(xml_hash['ROOT']['record']['transcript_alt_lang'])
        language = language.nil? ? 'en' : language
        alt_hash = parse_index(index_points, file_index, '_alt')
      end
      [hash, alt_hash, language]
    end

    def map_hash_to_db(file_index, hash, alt_hash = nil, language = nil)
      FileIndexPoint.transaction do
        raise ActiveRecord::Rollback unless file_index.file_index_points.create(hash)
      end
      if alt_hash.present?
        file_index_alt = FileIndex.new
        file_index_alt.title = "#{file_index.title} Alt"
        file_index_alt.language = language
        file_index_alt.associated_file = file_index.associated_file
        file_index_alt.is_public = file_index.is_public
        file_index_alt.collection_resource_file = file_index.collection_resource_file
        file_index_alt.user = file_index.user
        file_index_alt.sort_order = file_index.sort_order + 1
        file_index_alt.save
        file_index_alt.file_index_points.create(alt_hash)
      end
      file_index.collection_resource_file.collection_resource.reindex_collection_resource
      Success
    end
  end

  # TranscriptManager Class for managing the index import of OHMS, WebVTT and Simple text files
  class TranscriptManager
    include Dry::Transaction
    include ApplicationHelper
    step :process
    try :parse_ohms_xml
    try :parse_simple_text
    try :parse_transcript
    try :transcript_with_sync_point
    try :parse_webvtt
    step :map_hash_to_db

    def process(file_transcript, remove_title = nil)
      file_path = ENV['RAILS_ENV'] == 'production' ? file_transcript.associated_file.url : file_transcript.associated_file.path
      if ['application/xml', 'text/xml'].include? file_transcript.associated_file_content_type
        doc = Nokogiri::XML(open(file_path))
        xml_hash = Hash.from_xml(doc.to_s)
        hash, alt_hash, language = parse_ohms_xml(xml_hash, file_transcript)
        return hash if hash.failure?
        Success(map_hash_to_db(file_transcript, hash, alt_hash, language))
      elsif file_transcript.associated_file_content_type == 'text/vtt' || ['.vtt', '.webvtt'].include?(File.extname(file_transcript.associated_file_file_name).downcase)
        require 'webvtt'
        tmp = Tempfile.new("webvtt_#{Time.now.to_i}")
        if ENV['RAILS_ENV'] == 'production'
          tmp << URI.parse(file_path).read.force_encoding('UTF-8')
          tmp.flush
          file_path = tmp.path
        end
        webvtt = WebVTT.read(file_path)
        tmp.close
        hash = parse_webvtt(webvtt, remove_title)
        Success(map_hash_to_db(file_transcript, hash))
      else
        file_content = Rails.env.production? ? URI.parse(file_path).read : File.read(open(file_path))
        hash = parse_simple_text(file_content, file_transcript)
        Success(map_hash_to_db(file_transcript, hash))
      end
    end

    def parse_simple_text(file, file_transcript)
      regex = /\[([0-9:.]+)\]/ ## This is used when only start time is given in transcript
      start_end_regex = /([0-9:.]+)\t([0-9:.]+)/ ## This is used when both start and end time is given in transcript
      time_regex = /(^[0-9:.]+)/
      point_hash = []
      output = file.split(regex)
      if output.size <= 1 && file.scan(start_end_regex).length > 1 ## checking if both timestamps present
        output = file.scan(start_end_regex)
        output.each do |points|
          start_time = points[0]
          end_time = points[1]
          puts "TIME: #{start_time}\t#{end_time}"
          match_section = file.split("#{start_time}\t#{end_time}")
          text = match_section[1].split(time_regex)[0]
          puts "TEXT: #{text}"
          single_hash = {}
          single_hash['start_time'] = start_time.split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b } # convert time to seconds
          single_hash['end_time'] = end_time.split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b }
          single_hash['duration'] = single_hash['end_time'] - single_hash['start_time']
          single_hash['text'] = text
          point_hash << single_hash
        end
      elsif output.size <= 1 # There is no timestamp in the text file
        single_hash = {}
        single_hash['start_time'] = 0
        single_hash['end_time'] = file_transcript.collection_resource_file.duration
        single_hash['duration'] = single_hash['end_time'].to_f - single_hash['start_time'].to_f
        single_hash['text'] = output[0]
        point_hash << single_hash
      else
        counter = -1
        output.each do |point|
          unless point.empty?
            match_section = regex.match("[#{point}]")
            match_time = time_regex.match(point)
            if match_section.present? && match_time.present?
              single_hash = {}
              single_hash['start_time'] = point.split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b } # convert time to seconds
              single_hash['text'] = ''
              point_hash << single_hash
              counter += 1
              if counter != 0 # Set the end time for the previous point
                point_hash[counter - 1]['end_time'] = single_hash['start_time']
                point_hash[counter - 1]['duration'] = point_hash[counter - 1]['end_time'] - point_hash[counter - 1]['start_time']
              end
            else
              if counter == -1
                single_hash = {}
                single_hash['start_time'] = 0
                single_hash['text'] = ''
                point_hash << single_hash
                counter += 1
              end
              unless point_hash[counter].nil? # keep adding the Text to the same point until gets a new timestamp
                point_hash[counter]['text'] = point_hash[counter]['text'] + point
              end
            end
          end
        end
        last_hash_index = point_hash.size - 1 # update the end time and duration of the last point using file duration
        point_hash[last_hash_index]['end_time'] = file_transcript.collection_resource_file.duration
        point_hash[last_hash_index]['duration'] = point_hash[last_hash_index]['end_time'].to_f - point_hash[last_hash_index]['start_time'].to_f
        point_hash
      end
      Success(point_hash)
    end

    def parse_webvtt(webvtt, remove_title = nil)
      points_hash = []
      webvtt.cues.each do |cue|
        regex = /<v(.*?)>/ # regex to match the speaker tag in the text of webvtt
        match_result = regex.match(cue.text)
        speaker = match_result.present? ? match_result[1] : ''
        speaker = speaker
        single_hash = {}
        single_hash['title'] = cue.identifier.present? ? cue.identifier : '' unless remove_title.present?
        single_hash['start_time'] = cue.start.to_f
        single_hash['end_time'] = cue.end.to_f
        single_hash['duration'] = single_hash['end_time'] - single_hash['start_time']
        single_hash['text'] = cue.text.gsub(%r{<\/?[^>]*>}, '')
        single_hash['speaker'] = speaker
        single_hash['writing_direction'] = cue.style.present? ? cue.style : ''
        points_hash << single_hash
      end
      Success(points_hash)
    end

    def transcript_with_sync_point(transcript, sync_points)
      transcript = transcript.split("\n")
      begin
        sync_points.each do |sync|
          line = sync.split('(')[0].to_i - 1
          column = /\(([^)]+)\)/.match(sync)[1].to_i - 1
          words = transcript[line].split(' ')
          words[column] = "[smntb]#{words[column]}"
          transcript[line] = words.join(' ')
        end
        Success(transcript.join("\n"))
      rescue StandardError => ex
        Failure(ex.message)
      end
    end

    def parse_transcript(transcript, sync_points, file_transcript, interval)
      hash = []
      if sync_points.present?
        transcript = transcript_with_sync_point(transcript, sync_points)
        return transcript if transcript.failure?
        transcript = transcript.value!.split('[smntb]')
        sync_points << 'last' # need to store last additional text as well.
        sync_points.each_index do |index|
          single_hash = {}
          single_hash['start_time'] = index * (interval * 60)
          single_hash['end_time'] = single_hash['start_time'] + (interval * 60)
          single_hash['duration'] = single_hash['end_time'].to_f - single_hash['start_time'].to_f
          single_hash['text'] = transcript[index]
          hash << single_hash
        end
      else
        single_hash = {}
        single_hash['start_time'] = 0
        single_hash['end_time'] = file_transcript.collection_resource_file.duration
        single_hash['duration'] = single_hash['end_time'].to_f - single_hash['start_time'].to_f
        single_hash['text'] = transcript
        hash << single_hash
      end
      Success(hash)
    end

    def parse_ohms_xml(xml_hash, file_transcript)
      transcript = xml_hash['ROOT']['record']['transcript']
      sync = xml_hash['ROOT']['record']['sync']
      sync_info = sync.present? ? sync.split(':|') : nil
      interval = sync_info.present? ? sync_info[0] : nil
      sync_points = sync_info.present? ? sync_info[1].split('|') : nil
      hash = parse_transcript(transcript, sync_points, file_transcript, interval.to_f)
      return hash if hash.failure?
      translate = xml_hash['ROOT']['record']['translate']
      alt_hash = language = nil
      if translate.to_i == 1
        language = languages_array_simple[0].key(xml_hash['ROOT']['record']['transcript_alt_lang'])
        language = language.nil? ? 'en' : language
        transcript_alt = xml_hash['ROOT']['record']['transcript_alt']
        sync_alt = xml_hash['ROOT']['record']['sync_alt']
        sync_alt_info = sync_alt.present? ? sync_alt.split(':|') : nil
        sync_alt_interval = sync_alt_info.present? ? sync_alt_info[0] : nil
        sync_alt_points = sync_alt_info.present? ? sync_alt_info[1].split('|') : nil
        alt_hash = parse_transcript(transcript_alt, sync_alt_points, file_transcript, sync_alt_interval.to_f)
      end
      [hash, alt_hash, language]
    end

    def map_hash_to_db(file_transcript, hash, alt_hash = nil, language = nil)
      FileTranscriptPoint.transaction do
        raise ActiveRecord::Rollback unless file_transcript.file_transcript_points.create(hash.value!)
      end
      if alt_hash.present?
        file_transcript_alt = FileTranscript.new
        file_transcript_alt.title = "#{file_transcript.title} Alt"
        file_transcript_alt.language = language
        file_transcript_alt.associated_file = file_transcript.associated_file
        file_transcript_alt.is_public = file_transcript.is_public
        file_transcript_alt.collection_resource_file = file_transcript.collection_resource_file
        file_transcript_alt.user = file_transcript.user
        file_transcript_alt.sort_order = file_transcript.sort_order + 1
        file_transcript_alt.save
        file_transcript_alt.file_transcript_points.create(alt_hash.value!)
      end
      file_transcript.collection_resource_file.collection_resource.reindex_collection_resource
      Success
    end
  end
end
