# Delete Collections Worker to delete all related to deleted collections
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
