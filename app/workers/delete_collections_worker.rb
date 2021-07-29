# Delete Collections Worker to delete all related to deleted collections
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class DeleteCollectionsWorker
  include Sidekiq::Worker

  def perform(*_args)
    collections = Collection.unscoped.where(status: Collection.statuses[:deleted])
    unless collections.blank?
      collections.destroy_all
    end
  rescue StandardError => e
    puts e.backtrace.join("\n")
  end
end
