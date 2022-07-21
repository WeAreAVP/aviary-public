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
module Aviary
  POINTS_PER_PAGE = 7000.to_f
  # TranscriptManager Class for managing the index import of OHMS, WebVTT and Simple text files
  class OhmsTranscriptManager
    include Dry::Transaction
    include ApplicationHelper
    step :process
    try :parse_ohms_xml
    try :parse_simple_text
    try :parse_transcript
    try :transcript_with_sync_point
    try :parse_doc
    step :map_hash_to_db
    step :map_hash_to_db
    attr_accessor :from_resource_file
    attr_accessor :sync_interval

    def initialize
      self.from_resource_file = true
      self.sync_interval = 0.0
    end

    def process(file_transcript, _remove_title = nil, is_new = true, import = false)
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
      else
        file_content = Rails.env.production? ? URI.parse(file_path).read : File.read(open(file_path))
        hash = parse_text(file_content, file_transcript)
        response = map_hash_to_db(file_transcript, hash, is_new)
        Success(response)
      end
    rescue StandardError => ex
      import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process transcript file </strong> #{file_path}")) if import.present?
      puts ex
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

        point_hash[last_hash_index]['end_time'] = file_transcript.collection_resource_file.duration if from_resource_file
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
      reg_ex = speaker_regex
      file = file.delete("\r") # replace \r because it will create problem in parsing logic
      regex = /\[([0-9:.]+)\]/ ## This is used when only start time is given in transcript

      file = parse_notes_info(file, file_transcript, regex)
      file.squeeze("TRANSCRIPTION BEGIN\n\n")
      split_content = file.split("TRANSCRIPTION BEGIN\n\n")[1].split('TRANSCRIPTION END')[0] ## Get only transcript data from the file
      transcript_points_content = split_content.split("\n\n")
      point_hash = []
      counter = -1
      last_row = 0
      transcript_points_content.each do |transcript_point_content|
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
        final_text = final_text.gsub('<br>', "\n").gsub('<br/>', "\n")
        single_hash['text'] = final_text
        unless single_hash.nil? # keep adding the Text to the same point until gets a new timestamp
          text_raw = single_hash['text']
          row = 0
          column = 0
          if text_raw.present?
            text = text_raw.split("\n")
            unless text.empty?
              row = text.length
              column = text.last.length
            end
          end
          last_row += row
          single_hash['point_info'] = "#{last_row}(#{column})"
        end
        point_hash << single_hash
        counter += 1
        if counter != 0 # Set the end time for the previous point
          point_hash[counter - 1]['end_time'] = single_hash['start_time']
          point_hash[counter - 1]['duration'] = point_hash[counter - 1]['end_time'] - point_hash[counter - 1]['start_time']
        end
      end
      last_hash_index = point_hash.size - 1 # update the end time and duration of the last point using file duration
      point_hash[last_hash_index]['end_time'] = file_transcript.collection_resource_file.duration if from_resource_file
      point_hash[last_hash_index]['duration'] = point_hash[last_hash_index]['end_time'].to_f - point_hash[last_hash_index]['start_time'].to_f
      Success(point_hash)
    end

    def parse_simple_text(file, file_transcript)
      regex = /\[([0-9:.]+)\]/ ## This is used when only start time is given in transcript
      start_end_regex = /([0-9:.]+)\t([0-9:.]+)/ ## This is used when both start and end time is given in transcript
      time_regex = /(^[0-9:.]+)/
      file = file.delete("\r") # replace \r because it will create problem in parsing logic
      file = parse_notes_info(file, file_transcript, regex)
      output = file.split(regex)
      unless from_resource_file
        last_point = '00:00:00'
        time_different = sync_interval.to_f * 60
        output.each_with_index do |points, point_key|
          if points.match(/(^[0-9:.]+)/).present?
            time = last_point.split(':').map(&:to_f).inject(0) { |a, b| a * 60 + b } # convert time to seconds
            time += time_different
            time = Time.at(time).utc.strftime('%H:%M:%S')
            output[point_key] = time
            last_point = time
          end
        end
      end

      point_hash = point_hash(file, file_transcript, regex, time_regex, start_end_regex, output)
      Success(point_hash)
    end

    def read_notes_info(file_transcript, text = '')
      if text.blank?
        text = file_transcript.file_transcript_points.pluck(:text).join(' ')
      end
      text_list = text.split("\n")
      if file_transcript.point_notes_info.present?
        notes_info = file_transcript.point_notes_info
        text_list.each_with_index do |_single_point, single_index|
          if notes_info[single_index.to_s].present?
            notes = notes_info[single_index.to_s].split('|')
            prv_length = 0
            notes.each do |note|
              tag = note.split('-')
              temp = "[[footnote]]#{tag[0]}[[/footnote]]"
              text_list[single_index].insert((tag[1].to_i + prv_length), temp)
              prv_length += temp.length
            end
          end
        end
        text = text_list.join("\n")
        note_array = []
        note_array = JSON.parse(file_transcript.notes_info) if file_transcript.notes_info.present?
        if note_array.present?
          last = note_array.map { |item| '[[note]]' + item + "[[/note]]\n" }.join
          text += "\n[[footnotes]]\n#{last}[[/footnotes]]"
        end
      end

      text
    end

    def parse_notes_info(file, file_transcript, regex = /\[([0-9]{2}:[0-9:.]+)\]|([0-9]{2}:[0-9:.]+)/)
      new_file = file
      new_file = new_file.gsub(regex, '')
      new_file = new_file.split("\n")
      info_notes = {}
      new_file.each_with_index do |_line, line_index|
        if new_file[line_index].include?('[[footnote]]')
          foot_note_new = ''
          foot_prv_location = 0
          new_file[line_index].split('[[footnote]]').each_with_index do |foot, _foot_index|
            if foot.include?('[[/footnote]]')
              info_notes[line_index] = if info_notes[line_index].present?
                                         "#{info_notes[line_index]}|#{foot.split('[[/footnote]]')[0]}-#{foot_prv_location}"
                                       else
                                         "#{foot.split('[[/footnote]]')[0]}-#{foot_prv_location}"
                                       end
              foot = foot.split('[[/footnote]]')[1]
            end
            foot_note_new = "#{foot_note_new}#{foot}"
            foot_prv_location = foot_note_new.length
          end
          if foot_note_new.present?
            new_file[line_index] = foot_note_new
          end
        end
      end
      new_file = new_file.join("\n")
      if info_notes.present?
        file_transcript.point_notes_info = info_notes
        file_transcript.save
      end
      if new_file.include?('[[footnotes]]')
        notes_links = []
        item = new_file.split('[[footnotes]]')
        item[1] = item[1].gsub("\n", '').strip
        notes = item[1].split('[[note]]')
        notes.each_with_index do |note, _index|
          if note.include?('[[/note]]')
            notes_links << note.split('[[/note]]')[0]
          end
        end
        if notes_links.present?
          file_transcript.notes_info = notes_links.to_json
          file_transcript.save
        end
      end
      file = file.gsub(%r{\[\[footnote\]\](\d+)\[\[/footnote\]\]}, '')
      file = file.split('[[footnotes]]')[0]
      file
    end

    def parse_doc_text(file, file_transcript, regex = /\[([0-9]{2}:[0-9:.]+)\]|([0-9]{2}:[0-9:.]+)/)
      start_end_regex = /([0-9:.]+)\t([0-9:.]+)/ ## This is used when both start and end time is given in transcript
      time_regex = /(^[0-9:.]+)/
      file = file.force_encoding('UTF-8')
      file = parse_notes_info(file, file_transcript, regex)
      output = file.split(regex)
      output = output.drop(1) if output.size > 1 && output[0].scan(regex).blank? && from_resource_file ## check if header exists then drop it
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
        last_row = 0
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
          unless single_hash.nil? # keep adding the Text to the same point until gets a new timestamp
            text_raw = single_hash['text']
            row = 0
            column = 0
            if text_raw.present?
              text = text_raw.split("\n")
              unless text.empty?
                row = text.length
                column = text.last.length
              end
            end
            last_row += row
            single_hash['point_info'] = "#{last_row}(#{column})"
          end
          point_hash << single_hash
        end
      elsif output.size <= 1 # There is no timestamp in the text file
        last_row = 0
        single_hash = {}

        single_hash['start_time'] = 0
        single_hash['end_time'] = file_transcript.collection_resource_file.duration if from_resource_file
        single_hash['duration'] = single_hash['end_time'].to_f - single_hash['start_time'].to_f
        single_hash['text'] = output[0].gsub(/:\n+/, ': ').gsub(/\n{3,5}/, "\n\n").strip if output.present?
        unless single_hash.nil? # keep adding the Text to the same point until gets a new timestamp
          text_raw = single_hash['text']
          row = 0
          column = 0
          if text_raw.present?
            text = text_raw.split("\n")
            unless text.empty?
              row = text.length
              column = text.last.length
            end
          end
          last_row += row
          single_hash['point_info'] = "#{last_row}(#{column})"
        end
        point_hash << single_hash
      else
        counter = -1
        total_hrs = 0
        previous_timestamp = 0
        reset_timecode = 0
        last_row = 0
        text_transcript = ''
        output.each_with_index do |point, _index_key|
          unless point.empty?
            match_section = regex.match("[#{point}]")
            match_time = time_regex.match(point)
            if match_section.present? && match_time.present?
              single_hash = {}
              point = setup_timestamp(point) if ENV['IS_ASJPA'].eql?('true') && from_resource_file
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
              unless single_hash.nil? # keep adding the Text to the same point until gets a new timestamp
                text_raw = single_hash['text']
                row = 0
                column = 0
                if text_raw.present?
                  text = text_raw.split("\n")
                  unless text.empty?
                    row = text.length
                    column = text.last.length
                  end
                end
                last_row += row
                single_hash['point_info'] = "#{last_row}(#{column})"
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
                point_hash[counter]['text'] = point_hash[counter]['text'] + point
                text_transcript += ' ' + point_hash[counter]['text'] + "||-tran_end-|#{counter}|"
              end
            end
          end
        end

        counter_hash = 0
        if text_transcript.present?
          text_transcript_arr = text_transcript.split("\n")
          text_transcript_arr.each_with_index do |single_transcript_arr, key|
            if single_transcript_arr.include? "||-tran_end-|#{counter_hash}|"
              point_hash[counter_hash]['point_info'] = "#{key}(#{single_transcript_arr.index("||-tran_end-|#{counter_hash}|")})"
              counter_hash += 1
            end
          end
        end
        last_hash_index = point_hash.size - 1 # update the end time and duration of the last point using file duration
        point_hash[last_hash_index]['end_time'] = file_transcript.collection_resource_file.duration if from_resource_file
        point_hash[last_hash_index]['duration'] = point_hash[last_hash_index]['end_time'].to_f - point_hash[last_hash_index]['start_time'].to_f
        point_hash
      end
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
      last_row = 0
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
          unless single_hash.nil? # keep adding the Text to the same point until gets a new timestamp
            text_raw = single_hash['text']
            row = 0
            column = 0
            if text_raw.present?
              text = text_raw.split("\n")
              unless text.empty?
                row = text.length
                column = text.last.length
              end
            end
            last_row += row
            single_hash['point_info'] = "#{last_row}(#{column})"
          end
          hash << single_hash
        end
      else
        single_hash = {}
        single_hash['start_time'] = 0
        single_hash['end_time'] = file_transcript.collection_resource_file.duration if from_resource_file
        single_hash['duration'] = single_hash['end_time'].to_f - single_hash['start_time'].to_f
        single_hash['text'] = transcript
        hash << single_hash
      end
      Success(hash)
    end

    def parse_ohms_xml(xml_hash, file_transcript)
      transcript = xml_hash['ROOT']['record']['transcript']
      transcript = parse_notes_info(transcript, file_transcript)
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
      file_transcript.collection_resource_file.collection_resource.reindex_collection_resource if from_resource_file
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
