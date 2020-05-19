namespace :aviary do
  namespace :solr_index do
    desc 'Index all objects of Organization for Solr; in descending order'
    task organizations: :environment do
      failed = []
      Organization.order(id: :desc).all.each do |organization|
        begin
          Sunspot.index organization
          Sunspot.commit
          puts organization.id
        rescue StandardError => error
          puts error
          failed << organization.id
        end
      end
      puts "IDs of CollectionResourceFiles which couldn't be indexed: #{failed}" unless failed.empty?
    end
  end
end
