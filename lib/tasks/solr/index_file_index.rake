# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
namespace :aviary do
  namespace :solr_index do
    desc 'Index all objects of FileIndex for Solr; in descending order'
    task file_indexes: :environment do
      failed = []
      FileIndex.order(id: :desc).all.each do |file_index|
        begin
          Sunspot.index file_index
          Sunspot.commit
          puts file_index.id
        rescue StandardError => error
          puts error
          failed << file_index.id
        end
      end
      puts "IDs of FileIndex which couldn't be indexed: #{failed}" unless failed.empty?
    end
  end
end
