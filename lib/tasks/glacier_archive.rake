# lib/tasks/glacier_archive.rake
#
# namespace aviary
# The task is written to copy files from wasabi to AWS Glacier Archive
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
namespace :aviary do
  desc 'Backup all media files on AWS glacier'
  task media_backup: :environment do
    sync_logs = Logger.new("#{Rails.root}/log/sync.log")
    task_log_file = "#{Rails.root}/log/sync_#{Time.now}.log"
    sync_logs.info "Log file: #{task_log_file}"
    task_log = Logger.new(task_log_file)
    task_log.info 'Fetching resource files to be synced'
    sync_logs.info 'Fetching resource files to be synced'
    resource_files = CollectionResourceFile.includes(collection_resource: [:collection])
                                           .where('embed_type is null AND (archive_id is null OR DATE(resource_file_updated_at) > DATE(archive_date))')
                                           .where.not(collection_resources: { collection_id: nil })
                                           .where.not(collections: { organization_id: nil })
                                           .limit(10)
    glacier = Fog::AWS::Glacier.new(region: ENV['AWS_REGION'],
                                    aws_access_key_id: ENV['AWS_ACCESS_KEY'],
                                    aws_secret_access_key: ENV['AWS_SECRET_KEY'])
    vault = glacier.vaults.get(ENV['GLACIER_VAULT_NAME'])
    resource_files.each do |file|
      task_log.info "Parsing file ID: #{file.id}"
      sync_logs.info "Parsing file ID: #{file.id}"

      file_updated_at = file.resource_file.updated_at
      expiry = file.duration.to_f * 2
      file_path = file.resource_file.expiring_url(expiry.ceil)
      url = URI.parse(file_path)
      next unless url.host.present?

      path = Rails.root.join('tmp')
      sub_dir = Digest::MD5.hexdigest(url.to_s)
      destination_path = path.join(sub_dir)
      FileUtils.mkdir_p(destination_path.to_s) unless File.directory?(destination_path.to_s)
      dest_file = destination_path.join(file.resource_file_file_name)
      task_log.info 'Getting file from wasabi...'
      sync_logs.info 'Getting file from wasabi...'
      command = "wget -P #{destination_path} -O \"#{dest_file}\" \"#{url}\""
      sync_logs.info "command: #{command}"
      system(command)
      sync_logs.info 'file downloaded!!!'

      archive = vault.archives.create body: File.new(dest_file.to_s), multipart_chunk_size: 1024 * 1024

      if archive.id.present?
        sync_logs.info "Successfully uploaded, Archive id is #{archive.id}"
        task_log.info "Successfully uploaded, Archive id is #{archive.id}"
        archived_date = Time.now
        resource_file = CollectionResourceFile.where('DATE(resource_file_updated_at) < DATE(?)', archived_date)
                                              .where('DATE(resource_file_updated_at) = DATE(?)', Time.at(file_updated_at))
                                              .where('archive_date is null OR DATE(archive_date) < DATE(?)', archived_date)
                                              .where(id: file.id)
        if resource_file.present?
          resource_file.update(archive_id: archive.id, archive_date: archived_date)
          sync_logs.info "Media File# #{file.id} updated successfully"
          task_log.info "Media File# #{file.id} updated successfully"
        end
      else
        sync_logs.info 'Please Try again.'
        task_log.info 'Please Try again.'
      end
      File.delete(dest_file.to_s) if File.exist?(dest_file.to_s)
    end
    task_log.info 'Process ends'
    name = File.basename(task_log_file.to_s)
    s3_obj_key = "#{ENV['INSTANCE']}/#{Time.now.strftime('%Y-%m-%d')}/#{name}"
    s3 = Aws::S3::Resource.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY'],
      secret_access_key: ENV['AWS_SECRET_KEY']
    )
    obj = s3.bucket(ENV['LOGS_BUCKET']).object(s3_obj_key)
    obj.upload_file(task_log_file)
    File.delete(task_log_file) if File.exist?(task_log_file)
    sync_logs.info 'Process ends'
  end

  desc 'testing Upload CSV on s3 bucket with latest records'
  task testing: :environment do
    glacier = Fog::AWS::Glacier.new(region: ENV['AWS_REGION'],
                                    aws_access_key_id: ENV['AWS_ACCESS_KEY'],
                                    aws_secret_access_key: ENV['AWS_SECRET_KEY'])
    vault = glacier.vaults.get(ENV['GLACIER_VAULT_NAME'])
    puts 'uploading....'
    archive = vault.archives.create body: File.new('20191001_Kim_Youngjin_DMA_piano.mp4'), multipart_chunk_size: 1024 * 1024
    puts archive.inspect
  end
end
