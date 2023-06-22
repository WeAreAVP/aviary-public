# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class MediaFilesBulkExportWorker
  include Sidekiq::Worker
  delegate :url_helpers, to: 'Rails.application.routes'

  def perform(*args)
    Rails.logger.info 'Media files bulk export process started'
    puts 'Media files bulk export process started'
    @from_resource_import_export = true
    @notification = Notification.new
    org = Organization.find(args[4])
    base_url = args[5]
    params = {}
    params = JSON.parse(args[3].gsub('=>', ':')) if args[3].present?
    search_info = { search: { value: args[3].present? && params.present? && params['search'].present? ? params['search']['value'] : '' } }
    job = Aviary::ResourceFilesExportCsv.new.process_resource(args[1], search_info, org, base_url)
    if job
      @notification.subject = 'Media Files Export Completed Successfully'
      @notification.heading = 'Media Files Export Completed Successfully'
      Rails.application.routes.default_url_options[:protocol] = 'https'
      @link = url_helpers.download_export_file_collection_resources_url(id: job.id, download: 1, host: Utilities::AviaryDomainHandler.subdomain_handler(org))
      @notification.sub_heading = ''
      @notification.content = "The media files export job that you initiated in Aviary has completed. Please click on link to access the report <a download target='_blank' href='#{@link}'>click here</a>."
    else
      @notification.subject = 'Media Files Export Unsuccessful'
      @notification.heading = 'Media Files Export Unsuccessful'
      @file_path = false
      @notification.sub_heading = 'Media files export could not be completed successfully '
      @notification.content = 'Media files export unsuccessful. Please try again.'
      puts
    end
    UserMailer.notification_alert(User.find(args.third), @notification, @from_resource_import_export).deliver_now
  rescue StandardError => e
    @notification = Notification.new
    @notification.subject = 'Media Files Export Unsuccessful'
    @notification.heading = 'Media Files Export Unsuccessful'
    @file_path = false
    @notification.sub_heading = 'Media files export could not be completed successfully '
    @notification.content = 'Media files export unsuccessful. Please try again.' + e.message + e.backtrace.join("\n")
    UserMailer.notification_alert(User.find(args.third), @notification, @from_resource_import_export).deliver_now
    puts e
    Rails.logger.error e
    Rails.logger.error args
  end
end
