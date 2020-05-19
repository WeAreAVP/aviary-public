namespace :aviary do
  namespace :solr_index do
    desc 'Index all objects of given Class for Solr; in descending order'
    task :given_class, [:klass] => :environment do |_task, arguments|
      failed = []
      begin
        input = arguments[:klass].titleize.delete(' ')
        klass = input.constantize
      rescue NoMethodError => error
        if error.message == "undefined method `titleize' for nil:NilClass"
          puts 'Error: Incorrect invocation of rake task - Correct way is:   aviary:solr_index:given_class[GivenClass]'
        else
          puts error.message
        end
        exit
      rescue NameError => error
        puts "Error: No such class - #{input}"
        exit
      rescue StandardError => error
        puts error.message
        exit
      end
      klass.order(id: :desc).all.each do |obj|
        begin
          if obj.class == CollectionResource
            obj.reindex_collection_resource
          else
            Sunspot.index obj
            Sunspot.commit
          end
          puts obj.id
        rescue StandardError => error
          puts error
          failed << obj.id
        end
      end
      puts "IDs of #{klass} which couldn't be indexed: #{failed}" unless failed.empty?
    end
  end
end
