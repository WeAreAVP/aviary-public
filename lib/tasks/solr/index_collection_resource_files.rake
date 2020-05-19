namespace :aviary do
  namespace :solr_index do
    desc 'Index all objects of CollectionResourceFile for Solr; in descending order'
    task collection_resource_files: :environment do
      failed = []
      CollectionResourceFile.order(id: :desc).all.each do |collection_resource_file|
        begin
          Sunspot.index collection_resource_file
          Sunspot.commit
          puts collection_resource_file.id
        rescue StandardError => error
          puts error
          failed << collection_resource_file.id
        end
      end
      puts "IDs of CollectionResourceFiles which couldn't be indexed: #{failed}" unless failed.empty?
    end
  end
end
