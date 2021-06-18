class SeedTranscriptColumns < ActiveRecord::Migration[5.2]
  def change
    Organization.all.map(&:update_transcript_fields)
  end
end
