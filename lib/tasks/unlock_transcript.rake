# lib/tasks/unlock_transcript.rb
#
# namespace aviary
# The task is written to unlock any transcript that is in the edit mode
# and user forgot to unlock it.
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
namespace :aviary do
  desc 'Automated unlock the locked transcript after 24 hours'
  task unlock_transcript: :environment do
    puts 'Job started'
    transcripts = FileTranscript.where(is_edit: true)
    transcripts.each do |transcript|
      last_edit_datetime = Time.at(transcript.updated_at)
      time_difference = (Time.now.to_time - last_edit_datetime.to_time) / 1.hours
      puts "Time difference: #{time_difference}"
      if time_difference > 24
        transcript.update_attribute(:is_edit, false)
        puts "Transcript ID: #{transcript.id} unlocked"
      end
    end
    puts 'Job Ended'
  end
end
