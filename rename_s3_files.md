This will copy the file and change its name and delete the existing file.

        require 'rack/mime'
        s3 = Aws::S3::Client.new(
            access_key_id: ENV['WASABI_KEY'],
            secret_access_key: ENV['WASABI_SECRET'],
            region: ENV['WASABI_REGION'],
            endpoint: ENV['WASABI_ENDPOINT']
        )
        failed_id = []
        resource_files = CollectionResourceFile.where("resource_file_file_name LIKE 'open-uri%'")
        resource_files.each do |resource_file|
          if File.extname(resource_file.resource_file_file_name).blank?
            extension = Rack::Mime::MIME_TYPES.invert[resource_file.resource_file_content_type]
            begin
              s3.copy_object(bucket: resource_file.resource_file.bucket_name, copy_source: URI::encode("#{resource_file.resource_file.bucket_name}#{resource_file.resource_file.path}"), key: URI::encode("#{resource_file.resource_file.s3_object.key}#{extension}"))
              s3.delete_object(bucket: resource_file.resource_file.bucket_name, key: URI::encode(resource_file.resource_file.s3_object.key))
              resource_file.resource_file.instance_write(:file_name, "#{resource_file.resource_file_file_name}#{extension}")
              resource_file.save
            rescue StandardError
              failed_id << resource_file.id
            end
          end
        end
        puts failed_id