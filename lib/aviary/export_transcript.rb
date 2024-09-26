# services/aviary/export_transcript.rb
#
# Module Aviary::export_transcript
# The class is written for exporting the transcript in different formats
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # TaxJar Class for getting the Tax rates
  class ExportTranscript
    delegate :url_helpers, to: 'Rails.application.routes'

    def export(transcript, type)
      data = case type
             when 'webvtt'
               Rails.env.production? ? URI.parse(transcript.associated_file.url).read.force_encoding('UTF-8') : File.read(transcript.associated_file.path)
             when 'json'
               transcript.draftjs.present? ? transcript.draftjs : transcript.timestamps.gsub('=>', ':')
             when 'txt'
               prepare_plain_text(transcript)
             end
      data
    end

    def prepare_plain_text(transcript)
      collection_resource = transcript.collection_resource_file.collection_resource
      text = "AVIARY TRANSCRIPTION\n\n"
      text += "#{collection_resource.title}\n\n"
      text += "#{url_helpers.noid_url(noid: collection_resource.noid, host: Utilities::AviaryDomainHandler.subdomain_handler(collection_resource.collection.organization))}\n"
      text += "Media File: #{transcript.collection_resource_file.file_display_name}\n"
      text += "Transcription File: #{transcript.title}\n"
      text += "Plain Text Exported From Aviary: #{Time.now.strftime('%Y-%m-%dT%H:%M:%S')}\n\n\n"
      text += "TRANSCRIPTION BEGIN\n\n"
      transcript.file_transcript_points.each do |point|
        text += "[#{Time.at(point.start_time.to_f).utc.strftime('%H:%M:%S')}]\n"
        text += "#{point.speaker.upcase}: " if point.speaker.present?
        text += "#{point.text.strip}\n\n"
      end
      text += 'TRANSCRIPTION END'
      text
    end
  end
end
