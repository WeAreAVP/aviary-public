namespace :aviary do
  namespace :solr_index do
    desc 'Index all objects of CollectionResource for Solr; in descending order'
    task collection_resources: :environment do
      failed = []
      CollectionResource.order(id: :desc).all.each do |collection_resource|
        begin
          collection_resource.reindex_collection_resource
          puts collection_resource.id
        rescue StandardError => error
          puts error
          failed << collection_resource.id
        end
      end
      puts "IDs of CollectionResources which couldn't be indexed: #{failed}" unless failed.empty?
    end
  end
end
