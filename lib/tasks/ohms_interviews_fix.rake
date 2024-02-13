# lib/tasks/ohms_interviews_fix.rb
#
# namespace aviary
# The task is written to fix ohms interviews
#
# Author::    Raza Saleem  (mailto:raza@weareavp.com)
namespace :aviary do
    desc 'fix ohms interviews'
    task ohms_interviews_fix: :environment do
      puts 'Job started'
      failed = []
      Organization.all.each do |org|
        interviews = org.interviews.all
        if interviews.length.positive?
          interviews.each do |interview|
            begin
              interview.reindex
            rescue StandardError => error
              puts error
              failed << interview.id
            end
          end
        end
      end
      puts "IDs of interviews which couldn't be indexed: #{failed}" unless failed.empty?
      puts 'Job Ended'
    end
  
  end