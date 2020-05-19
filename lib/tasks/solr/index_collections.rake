namespace :aviary do
  namespace :solr_index do
    desc 'Index all objects of Collection for Solr; in descending order'
    task collections: :environment do
      failed = []
      Collection.order(id: :desc).all.each do |collection|
        begin
          Sunspot.index collection
          Sunspot.commit
          puts collection.id
        rescue StandardError => error
          puts error
          failed << collection.id
        end
      end
      puts "IDs of CollectionResourceFiles which couldn't be indexed: #{failed}" unless failed.empty?
    end
  end
end
