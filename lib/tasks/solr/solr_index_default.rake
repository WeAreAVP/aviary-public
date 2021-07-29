# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
namespace :aviary do
  namespace :solr_index do
    desc 'Index all objects of Collection for Solr; in descending order'
    task default: :environment do
      %w'Organization Collection CollectionResource CollectionResourceFile'.each do |klass|
        klass = klass.titleize.delete(' ').constantize
        failed = []
        puts "IDs of #{klass} which are successfully indexed"
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
end
