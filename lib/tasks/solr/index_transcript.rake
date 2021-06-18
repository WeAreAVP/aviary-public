namespace :aviary do
  namespace :solr_index do
    desc 'Index all objects of FileTranscript for Solr; in descending order'
    task transcripts: :environment do
      failed = []
      FileTranscript.order(id: :desc).all.each do |transcript|
        begin
          Sunspot.index transcript
          Sunspot.commit
          puts transcript.id
        rescue StandardError => error
          puts error
          failed << transcript.id
        end
      end
      puts "IDs of FileTranscript which couldn't be indexed: #{failed}" unless failed.empty?
    end
  end
end
