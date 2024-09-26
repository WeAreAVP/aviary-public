# app/workers/resource_bulk_import_worker.rb
#
# Class InterviewBulkExportWorker
# The class is written to run the Resource Bulk Export script in the background using Sidekiq gem
#
# Author::    Raza Saleem  (mailto:raza@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class InterviewBulkExportWorker
  include Sidekiq::Worker
  include XMLFileHandler
  include Aviary::ZipperService

  delegate :url_helpers, to: 'Rails.application.routes'

  def perform(*args)
    @notification = {}
    @notification[:subject] = 'OHMS XML Metadata Export Completed Successfully'
    @notification[:heading] = 'OHMS XML Metadata Export Completed Successfully'
    @notification[:sub_heading] = ''
    @notification[:content] = 'The OHMS Interview XML export that you initiated in Aviary has completed. Please click here to download a zip file containing the XMLs.'

    user = User.find(args[1])
    organizaion = Organization.find(args[2])
    interviews = Interviews::Interview.fetch_interview_list(1, 10_000_000, [], '', { collection_id: args[0] }, {}, export: false, current_organization: organizaion)

    self.tmp_user_folder = "public/zips/archive_#{args[1]}_#{Time.now.to_i}"
    dos_xml = []
    dos_xml_files = []
    FileUtils.mkdir_p(tmp_user_folder)
    interviews.try(:first).each do |interview_solr|
      interview = Interviews::Interview.find_by(id: interview_solr['id_is'])
      export_text = Aviary::ExportOhmsInterviewXML.new.export(interview)
      doc = Nokogiri::XML(export_text.to_xml)
      error_messages = xml_validation(doc)
      unless error_messages.any?
        dos_xml << { xml: export_text.to_xml, title: interview.title, id: interview.id, ohms_xml_filename: interview.miscellaneous_ohms_xml_filename }
      end
    end
    if dos_xml.present?
      dos_xml.each_with_index do |single_dos_xml, index|
        file_name = single_dos_xml[:ohms_xml_filename].present? ? Time.now.to_i.to_s + index.to_s + single_dos_xml[:ohms_xml_filename] : Time.now.to_i.to_s + 'interview' + index.to_s + single_dos_xml[:id].to_s + '.xml'
        File.binwrite(File.join(tmp_user_folder, file_name), single_dos_xml[:xml])
        dos_xml_files << file_name.to_s
      end
    end
    file_path = Rails.root.join("#{tmp_user_folder}/#{Time.now.to_i}.zip")
    zip_data = process_and_create_zip_file(dos_xml_files, file_path, true)
    UserMailer.notification_alert(user, @notification, true, zip_data).deliver_now
  rescue StandardError => e
    puts e
    Rails.logger.error e
    Rails.logger.error args
  end
end
