# services/aviary/index_transcript_manager.rb
#
# Module Aviary::IndexTranscriptManager
# The module is written to store the index and transcript for the collection resource file
# Currently supports OHMS XML and WebVtt format
# Nokogiri, webvtt-ruby gem is needed to run this module successfully
# dry-transaction gem is needed for adding transcript steps to this process
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary::IndexTranscriptManager
  POINTS_PER_PAGE = 7000.to_f
  # IndexManager Class for managing the index import of OHMS and WebVTT files
  class IndexManager
    include Dry::Transaction
    include ApplicationHelper
    step :process
    try :parse_webvtt
    try :parse_ohms_xml
    step :map_hash_to_db

    def process(file_index, is_new = true, import = false)
      file_path = ENV['RAILS_ENV'] == 'production' ? file_index.associated_file.expiring_url : file_index.associated_file.path
      if ['application/xml', 'text/xml'].include? file_index.associated_file_content_type
        doc = Nokogiri::XML(open(file_path))
        xml_hash = Hash.from_xml(doc.to_s)
        hash, alt_hash, language = parse_ohms_xml(xml_hash, file_index)
        map_hash_to_db(file_index, hash, is_new, alt_hash, language)
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
        map_hash_to_db(file_index, hash, is_new)
      end
    rescue StandardError => ex
      import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process Index file #{file_path}")) if import.present?
      puts ex
    end

    def parse_webvtt(webvtt)
      index_hash = []
      webvtt.cues.each do |cue|
        metadata = parse_metadata(cue)
        single_hash = {}
        json_array = [].to_json
        single_hash['gps_latitude'] = metadata['gps_lat'].present? ? [metadata['gps_lat']].to_json : json_array
        single_hash['gps_longitude'] = metadata['gps_lng'].present? ? [metadata['gps_lng']].to_json : json_array
        single_hash['gps_zoom'] = metadata['gps_zoom_level'].present? ? [metadata['gps_zoom_level']].to_json : json_array
        single_hash['gps_description'] = metadata['gps_description'].present? ? [metadata['gps_description']].to_json : json_array
        single_hash['hyperlink'] = metadata['hyperlink'].present? ? [metadata['hyperlink']].to_json : json_array
        single_hash['hyperlink_description'] = metadata['hyperlink_description'].present? ? [metadata['hyperlink_description']].to_json : json_array
        single_hash['partial_script'] = metadata['partial_transcript'].present? ? metadata['partial_transcript'] : ''
        single_hash['subjects'] = ''
        single_hash['keywords'] = ''
        single_hash['title'] = cue.identifier.present? ? cue.identifier : index_hash.size + 1
        single_hash['start_time'] = cue.start.to_f
        single_hash['end_time'] = cue.end.to_f
        single_hash['duration'] = single_hash['end_time'] - single_hash['start_time']
        single_hash['synopsis'] = cue.text.present? ? cue.text.gsub(/\n*{.*}\n*/, '').gsub(%r{/<\/?[^>]*>}, '') : ''
        index_hash << single_hash
      end
      index_hash
    end

    def parse_metadata(cue)
      string_metadata = cue.text.scan(/{.*}\n*/)
      metadata = {}

      return metadata unless string_metadata.present?

      string_metadata.each do |data|
        data = JSON.parse(data)
        next unless data['value'].present?

        key = data['label']['en'][0].strip.downcase.parameterize(separator: '_')

        if %w[gps_description gps_zoom_level gps_coordinates hyperlink hyperlink_description].include?(key)
          if key == 'gps_coordinates'
            coordinates = data['value'].split(';')
            metadata['gps_lat'] = []
            metadata['gps_lng'] = []

            coordinates.each do |coordinate|
              coordinate = coordinate.split(',')
              next unless coordinate.length == 2

              metadata['gps_lat'].push(coordinate[0].strip)
              metadata['gps_lng'].push(coordinate[1].strip)
            end
          else
            metadata[key] = data['value'].split(',').map(&:strip)
          end
        else
          metadata[key] = data['value'].strip
        end
      end

      metadata
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

    def update_existing_points(file_index, full_hash)
      existing_index = file_index.file_index_points
      existing_ids = existing_index.map(&:id)
      update_ids = []
      full_hash.each_with_index do |hash, index|
        if existing_index[index].present?
          existing_index[index].update(hash)
          update_ids << existing_index[index].id
        else
          new_point = file_index.file_index_points.create(hash)
          update_ids << new_point.id
        end
      end
      deletable_ids = existing_ids - update_ids
      file_index.file_index_points.where(id: deletable_ids).destroy_all if deletable_ids.present?
    end

    def map_hash_to_db(file_index, hash, is_new, alt_hash = nil, language = nil)
      FileIndexPoint.transaction do
        if is_new
          raise ActiveRecord::Rollback unless file_index.file_index_points.create(hash)
        else
          update_existing_points(file_index, hash)
        end
      end
      update_parents(file_index)
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
        update_parents(file_index_alt)
      end
      file_index.collection_resource_file.collection_resource.reindex_collection_resource
      Success
    end

    def update_parents(file_index)
      file_index.file_index_points.each do |x1|
        file_index.file_index_points.each do |x2|
          if x1.id != x2.id && (x1.start_time.to_f >= x2.start_time.to_f && x1.end_time.to_f <= x2.end_time.to_f)
            x1.parent_id = x2.id
            x1.save
          end
        end
      end
    end
  end

  # TranscriptManager Class for managing the index import of OHMS, WebVTT and Simple text files
  class TranscriptManager
    attr_accessor :annotations

    include Dry::Transaction
    include ApplicationHelper
    step :process
    try :parse_ohms_xml
    try :parse_simple_text
    try :parse_transcript
    try :transcript_with_sync_point
    try :parse_webvtt
    try :parse_doc
    step :map_hash_to_db

    def process(file_transcript, remove_title = nil, is_new = true, import = false)
      file_path = ENV['RAILS_ENV'] == 'production' ? file_transcript.associated_file.expiring_url : file_transcript.associated_file.path
      if ['application/xml', 'text/xml'].include? file_transcript.associated_file_content_type
        doc = Nokogiri::XML(open(file_path))
        xml_hash = Hash.from_xml(doc.to_s)
        hash, alt_hash, language = parse_ohms_xml(xml_hash, file_transcript)
        return hash if hash.failure?
        Success(map_hash_to_db(file_transcript, hash, is_new, alt_hash, language))
      elsif file_transcript.associated_file_content_type == 'application/msword'
        require 'yomu'
        yomu = Yomu.new file_path
        file_content = yomu.text
        hash = parse_doc_text(file_content, file_transcript)
        response = map_hash_to_db(file_transcript, hash, is_new)
        Success(response)
      elsif ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/msword'].include? file_transcript.associated_file_content_type
        require 'docx'
        doc = Docx::Document.open(open(file_path))
        file_content = ''
        doc.paragraphs.each do |p|
          file_content = "#{file_content}\n\n#{p}"
        end

        hash = parse_doc_text(file_content, file_transcript)
        if hash.value!.blank?
          hash = parse_doc(doc, file_transcript)
        end
        if hash.value!.present?
          Success(map_hash_to_db(file_transcript, hash, is_new))
        else
          Failure('No transcript point available.')
        end
      elsif ['application/zip'].include? file_transcript.associated_file_content_type
        require 'docx'
        doc = Docx::Document.open(open(file_path))
        file_content = ''
        doc.paragraphs.each do |p|
          file_content = "#{file_content}\n#{p}"
        end

        hash = parse_doc_text(file_content, file_transcript)
        if hash.value!.blank?
          hash = parse_doc(doc, file_transcript)
        end
        if hash.value!.present?
          Success(map_hash_to_db(file_transcript, hash, is_new))
        else
          Failure('No transcript point available.')
        end
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
        header_info = webvtt.header.split("\n")
        language_index = header_info.index { |s| s.downcase =~ /language:/ }
        if language_index.present?
          language = header_info[language_index].downcase.gsub('language:', '').strip
          language_code = ISO_639.find_by_code(language).try(:alpha2)
          file_transcript.update(language: language_code) if language_code.present?
        end
        Success(map_hash_to_db(file_transcript, hash, is_new))
      else
        file_content = Rails.env.production? ? URI.parse(file_path).read : File.read(open(file_path))
        hash = parse_text(file_content, file_transcript)
        response = map_hash_to_db(file_transcript, hash, is_new)
        parse_annotation(file_content, file_transcript) if annotations.present?
        Success(response)
      end
    rescue StandardError => ex
      import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process transcript file </strong> #{file_path}")) if import.present?
      puts ex
    end

    def parse_annotation(content, transcript)
      transcript_points = transcript.file_transcript_points
      transcript.annotation_set.destroy if transcript.annotation_set.present?
      split_content = content.split("ANNOTATIONS BEGIN\n\n")[1].split("\n\nANNOTATIONS END")[0]
      annotation_split = split_content.split("\n\n")
      annotation_set_content = annotation_split[0].split("\n")
      annotation_set_db = AnnotationSet.new
      annotation_set_db.is_public = transcript.is_public
      annotation_set_db.organization = transcript.collection_resource_file.collection_resource.collection.organization
      annotation_set_db.collection_resource = transcript.collection_resource_file.collection_resource
      annotation_set_db.created_by_id = transcript.user_id
      annotation_set_db.updated_by_id = transcript.user_id
      annotation_set_db.file_transcript_id = transcript.id
      dublin_core = []

      annotation_set_content.each do |annotation_set|
        key_value = annotation_set.split(':', 2)
        key = key_value[0].gsub('Annotation Set ', '')
        value = key_value[1].strip
        if key == 'Title'
          annotation_set_db.title = value
        else
          dublin_core << { key: key, value: value }
        end
      end
      annotation_set_db.dublin_core = dublin_core.to_json
      annotation_set_db.save
      counter = 0
      annotations_content = annotation_split[1]
      annotations_content_split = annotations_content.split(/\[[0-9]+\]/)
      annotations_content_split.delete_at(0)
      annotations.each_with_index do |value, index|
        value.each do |target|
          annotation_db = Annotation.new
          annotation_db.annotation_set = annotation_set_db
          annotation_db.sequence = counter + 1
          annotation_db.body_type = :text
          annotation_db.body_content = annotations_content_split[counter].strip
          annotation_db.body_format = :html
          annotation_db.target_type = :text
          annotation_db.target_content = :FileTranscript
          annotation_db.target_content_id = transcript.id
          annotation_db.target_info = target.merge(pointId: transcript_points[index].id).to_json
          annotation_db.created_by_id = annotation_set_db.created_by_id
          annotation_db.updated_by_id = annotation_set_db.updated_by_id
          annotation_db.target_sub_id = transcript_points[index].id
          annotation_db.save
          counter += 1
        end
      end
    rescue StandardError
      'failed to process annotations content'
    end

    def parse_doc(doc, file_transcript)
      point_hash = []
      counter = -1
      doc.paragraphs.each_with_index do |p, _key|
        regex = /\[([0-9:.]+)\]/ ## This is used when only start time is given in transcript
        output = p.to_s.split(regex)
        length = output.count
        next if length < 2
        single_hash = {}
        speaker = length == 3 ? output[0].strip : ''
        start_time = length == 3 ? output[1].strip : output[0].strip
        text = length == 3 ? output[2].strip : output[1].strip
        single_hash['speaker'] = speaker
        single_hash['start_time'] = start_time.split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b }

        single_hash['text'] = text.strip
        point_hash << single_hash
        counter += 1
        if counter != 0 # Set the end time for the previous point
          point_hash[counter - 1]['end_time'] = single_hash['start_time']
          point_hash[counter - 1]['duration'] = point_hash[counter - 1]['end_time'] - point_hash[counter - 1]['start_time']
        end
      end
      unless point_hash.empty?
        last_hash_index = point_hash.size - 1 # update the end time and duration of the last point using file duration
        point_hash[last_hash_index]['end_time'] = file_transcript.collection_resource_file.duration
        point_hash[last_hash_index]['duration'] = point_hash[last_hash_index]['end_time'].to_f - point_hash[last_hash_index]['start_time'].to_f
      end
      Success(point_hash)
    end

    def parse_text(file_content, file_transcript)
      if file_content.include?('AVIARY TRANSCRIPTION')
        parse_aviary_text(file_content, file_transcript)
      else
        parse_simple_text(file_content, file_transcript)
      end
    end

    def parse_aviary_text(file, file_transcript)
      self.annotations = []
      reg_ex = speaker_regex
      file = file.delete("\r") # replace \r because it will create problem in parsing logic
      split_content = file.split("TRANSCRIPTION BEGIN\n\n")[1].split('TRANSCRIPTION END')[0] ## Get only transcript data from the file
      transcript_points_content = split_content.split("\n\n")
      point_hash = []
      counter = -1
      transcript_points_content.each do |transcript_point_content|
        regex = /\[([0-9:.]+)\]/ ## This is used when only start time is given in transcript
        output = transcript_point_content.split(regex)
        mix_content = output[2].blank? ? [''] : output[2].lstrip.split("\n")
        single_hash = {}

        single_hash['start_time'] = output[1].split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b }
        speaker_and_text = mix_content[0].split(reg_ex)
        speaker_offset = 0
        if speaker_and_text.size == 1
          text = speaker_and_text[0]
          speaker = ''
        elsif speaker_and_text.size == 3
          text = speaker_and_text.last.strip
          speaker = speaker_and_text.second.delete(':').strip
          speaker_offset += speaker.length + 2
        else
          speaker = ''
          speaker_offset = 0
          text = mix_content[0]
        end
        text = text.force_encoding('UTF-8')
        single_hash['speaker'] = speaker
        annotation_regex = %r{<annotation [^>]+>(.*?)<\/annotation>}
        anno_output = text.split(annotation_regex)
        final_text = ''
        single_hash['annotation'] = []
        anno_output.each_with_index do |value, index|
          unless index.zero? || index.even?
            start_offset = final_text.length + speaker_offset
            single_hash['annotation'] << { time: single_hash['start_time'], text: value, startOffset: start_offset, endOffset: start_offset + value.length }
          end
          final_text += value
        end
        annotations << single_hash['annotation']
        single_hash.delete('annotation')
        single_hash['text'] = final_text
        point_hash << single_hash
        counter += 1
        if counter != 0 # Set the end time for the previous point
          point_hash[counter - 1]['end_time'] = single_hash['start_time']
          point_hash[counter - 1]['duration'] = point_hash[counter - 1]['end_time'] - point_hash[counter - 1]['start_time']
        end
      end
      last_hash_index = point_hash.size - 1 # update the end time and duration of the last point using file duration
      point_hash[last_hash_index]['end_time'] = file_transcript.collection_resource_file.duration
      point_hash[last_hash_index]['duration'] = point_hash[last_hash_index]['end_time'].to_f - point_hash[last_hash_index]['start_time'].to_f
      Success(point_hash)
    end

    def parse_simple_text(file, file_transcript)
      regex = /\[([0-9:.]+)\]/ ## This is used when only start time is given in transcript
      start_end_regex = /([0-9:.]+)\t([0-9:.]+)/ ## This is used when both start and end time is given in transcript
      time_regex = /(^[0-9:.]+)/

      output = file.split(regex)
      point_hash = point_hash(file, file_transcript, regex, time_regex, start_end_regex, output)
      Success(point_hash)
    end

    def parse_doc_text(file, file_transcript, regex = /\[([0-9]{2}:[0-9:.]+)\]|([0-9]{2}:[0-9:.]+)/)
      start_end_regex = /([0-9:.]+)\t([0-9:.]+)/ ## This is used when both start and end time is given in transcript
      time_regex = /(^[0-9:.]+)/
      file = file.force_encoding('UTF-8')
      output = file.split(regex)
      output = output.drop(1) if output.size > 1 && output[0].scan(regex).blank? ## check if header exists then drop it
      # output = output.drop(output.size - 1) if output.size >= 1 && output[output.size - 1].scan(regex).blank? ## check if footer exists then drop it
      point_hash = point_hash(file, file_transcript, regex, time_regex, start_end_regex, output)
      Success(point_hash)
    end

    def reset_time(start_time)
      time = start_time.split(':')
      time.map(&:to_f).inject(0) { |a, b| a * 60 + b }
    end

    def point_hash(file, file_transcript, regex, time_regex, start_end_regex, output)
      point_hash = []
      if file.scan(start_end_regex).length > 1 ## checking if both timestamps present
        output = file.scan(start_end_regex)
        total_hrs = 0
        previous_timestamp = 0
        reset_timecode = 0
        output.each_with_index do |points, _point_key|
          start_time = points[0]
          end_time = points[1]
          start_time = setup_timestamp(start_time) if ENV['IS_ASJPA'].eql?('true')
          end_time = setup_timestamp(end_time) if ENV['IS_ASJPA'].eql?('true')
          match_section = file.split("#{start_time}\t#{end_time}")
          text = match_section[1].split(time_regex)[0]
          single_hash = {}
          single_hash['start_time'] = start_time.split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b } # convert time to seconds
          single_hash['end_time'] = end_time.split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b }

          total_hrs += 1 if previous_timestamp > single_hash['start_time']
          previous_timestamp = single_hash['start_time']
          single_hash['start_time'] = single_hash['start_time'] + (total_hrs * 3600)
          single_hash['end_time'] = single_hash['end_time'] + (total_hrs * 3600)

          if ENV['IS_ASJPA'].eql?('true') && reset_timecode == 0 && file_transcript.is_reset_timestamp == 1
            reset_timecode = single_hash['start_time']
            single_hash['start_time'] = 0
            single_hash['end_time'] = single_hash['end_time'] - reset_timecode
          elsif ENV['IS_ASJPA'].eql?('true') && reset_timecode > 0 && file_transcript.is_reset_timestamp == 1
            single_hash['start_time'] = single_hash['start_time'] - reset_timecode
            single_hash['end_time'] = single_hash['end_time'] - reset_timecode
          end
          single_hash['duration'] = single_hash['end_time'] - single_hash['start_time']
          single_hash['text'] = text.lstrip.gsub(/:\n+/, ': ').gsub(/\n{3,5}/, "\n\n").strip
          point_hash << single_hash
        end
      elsif output.size <= 1 # There is no timestamp in the text file
        single_hash = {}
        single_hash['start_time'] = 0
        single_hash['end_time'] = file_transcript.collection_resource_file.duration
        single_hash['duration'] = single_hash['end_time'].to_f - single_hash['start_time'].to_f
        single_hash['text'] = output[0].gsub(/:\n+/, ': ').gsub(/\n{3,5}/, "\n\n").strip
        point_hash << single_hash
      else
        counter = -1
        total_hrs = 0
        previous_timestamp = 0
        reset_timecode = 0
        output.each_with_index do |point, _index_key|
          unless point.empty?
            match_section = regex.match("[#{point}]")
            match_time = time_regex.match(point)
            if match_section.present? && match_time.present?
              single_hash = {}
              point = setup_timestamp(point) if ENV['IS_ASJPA'].eql?('true')
              if point.split(':').size == 4
                point = point.sub(/.*\K:/, '.')
              end
              single_hash['start_time'] = point.split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b } # convert time to seconds
              total_hrs += 1 if previous_timestamp > single_hash['start_time']
              previous_timestamp = single_hash['start_time']
              single_hash['start_time'] = single_hash['start_time'] + (total_hrs * 3600)

              if ENV['IS_ASJPA'].eql?('true') && reset_timecode == 0 && file_transcript.is_reset_timestamp == 1
                reset_timecode = single_hash['start_time']
                single_hash['start_time'] = 0
              elsif ENV['IS_ASJPA'].eql?('true') && reset_timecode > 0 && file_transcript.is_reset_timestamp == 1
                single_hash['start_time'] = single_hash['start_time'] - reset_timecode
              end

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
                point_hash[counter]['text'] = point_hash[counter]['text'].gsub(/\n{3,10}/, "\n\n").strip + point.gsub(/:\n+/, ': ').gsub(/\n{3,5}/, "\n\n").strip
              end
            end
          end
        end
        last_hash_index = point_hash.size - 1 # update the end time and duration of the last point using file duration
        point_hash[last_hash_index]['end_time'] = file_transcript.collection_resource_file.duration
        point_hash[last_hash_index]['duration'] = point_hash[last_hash_index]['end_time'].to_f - point_hash[last_hash_index]['start_time'].to_f
        point_hash
      end
    end

    def parse_webvtt(webvtt, remove_title = nil)
      points_hash = []
      webvtt.cues.each do |cue|
        next if cue.text.match(%r{<c>.+?</c>}).present?
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
        if points_hash.last.present? && single_hash['text'].include?(points_hash.last['text'])
          single_hash['text'] = single_hash['text'].gsub(points_hash.last['text'], '').strip
        end
        unless single_hash['text'].blank?
          points_hash << single_hash
        end
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

    def update_existing_points(file_transcript, full_hash)
      existing_transcript = file_transcript.file_transcript_points
      existing_ids = existing_transcript.map(&:id)
      update_ids = []
      full_hash.each_with_index do |hash, index|
        if existing_transcript[index].present?
          existing_transcript[index].update(title: hash['title'].to_s,
                                            start_time: hash['start_time'],
                                            end_time: hash['end_time'],
                                            duration: hash['duration'],
                                            speaker: hash['speaker'].to_s,
                                            text: hash['text'].to_s,
                                            writing_direction: hash['writing_direction'],
                                            word_timestamp: hash['word_timestamp'])
          update_ids << existing_transcript[index].id
        else
          new_point = file_transcript.file_transcript_points.create(hash)
          update_ids << new_point.id
        end
      end
      deletable_ids = existing_ids - update_ids
      file_transcript.file_transcript_points.where(id: deletable_ids).destroy_all if deletable_ids.present?
    end

    def map_hash_to_db(file_transcript, hash, is_new, alt_hash = nil, language = nil)
      FileTranscriptPoint.transaction do
        if is_new
          raise ActiveRecord::Rollback unless file_transcript.file_transcript_points.create(hash.value!)
        else
          update_existing_points(file_transcript, hash.value!)
        end
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

    def setup_timestamp(point)
      point = "00:#{point}" if point.split(':').size == 3
      if point.split(':').size == 4
        point = point.split(':')
        point[0] = '00'
        point = point.join(':')
      end
      point
    end
  end
end
