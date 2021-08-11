# services/aviary/resource_manager.rb
#
# Module Aviary::ResourceManager
# The module is written to map and store the resource related info in the Aviary system
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
# TODO: Need to cleanup this ResourceManager Class
module Aviary
  # ResourceManager Class for managing and mapping the resource information
  class ResourceManager
    PREVIEW_ONLY = 1
    INSERT_ONLY = 2
    include ApplicationHelper
    include Rails.application.routes.url_helpers
    require 'zip'
    # Method to create a new resource and its description fields with values
    def create_resource_and_description(resource, import)
      return unless resource.present?
      if resource[:resource_file].present? && import.import_type == Import::ImportType::OHMS_XML && resource[:resource_file][:host][:value].casecmp('aviary').zero? && resource[:resource_file][:link][:value].include?('<code>')
        import.import_error_manager(BulkImportManager.error_reporting("<strong>skipping media file </strong> #{resource[:resource_file]}"))
        return
      end

      is_public = resource[:access]
      is_featured = resource[:is_featured]

      value_custom_unique_identifier = begin
                                         resource[:custom_unique_identifier] = clean_uri(resource[:custom_unique_identifier])
                                       rescue StandardError => e
                                         import.import_error_manager(BulkImportManager.error_reporting("<strong>failing setting up custom_unique_identifier </strong> #{e}"))
                                         as_config.logger.fatal "failing setting up custom_unique_identifier #{e}"
                                         ''
                                       end

      custom_unique_identifier = value_custom_unique_identifier.present? ? value_custom_unique_identifier : ''
      if import.import_type == Import::ImportType::OHMS_XML && resource[:resource_file].present? && resource[:resource_file][:host][:value].casecmp('aviary').zero?
        resource_file = CollectionResourceFile.find_by(id: resource[:resource_file][:link][:media_id])
        if import.organization_id == resource_file.collection_resource.collection.organization.id
          collection_resource = resource_file.collection_resource
          update_fields = {}

          if resource[:access]
            update_fields[:access] = is_public
          else
            import.import_error_manager(BulkImportManager.error_reporting("<strong> Resource access value not found .</strong> #{resource[:title]}"))
          end

          if resource[:title]
            update_fields[:title] = resource[:title]
          else
            import.import_error_manager(BulkImportManager.error_reporting("<strong> Resource title not found .</strong> #{resource[:title]}"))
          end

          if resource[:is_featured]
            update_fields[:is_featured] = is_featured
          else
            import.import_error_manager(BulkImportManager.error_reporting("<strong> Resource is_featured value not found .</strong> #{resource[:title]}"))
          end

          update_fields[:external_resource_id] = import.id
          update_fields[:custom_unique_identifier] = custom_unique_identifier if custom_unique_identifier.present?
          collection_resource.update(update_fields)
        end
      else
        begin
          collection_resource = import.collection.collection_resources.create!(title: resource[:title], access: is_public,
                                                                               is_featured: is_featured, custom_unique_identifier: custom_unique_identifier, external_resource_id: import.id)
        rescue StandardError
          begin
            collection_resource = import.collection.collection_resources.create(title: resource[:title], access: is_public,
                                                                                is_featured: is_featured, custom_unique_identifier: '', external_resource_id: import.id)
          rescue StandardError
            import.import_error_manager(BulkImportManager.error_reporting("<strong> Retrying processing resource .</strong> #{resource[:title]}"))
            import.import_error_manager(BulkImportManager.error_reporting("<strong> unable to process resource .</strong> #{resource[:title]}"))
          end
        end
      end
      manage_resource_import(collection_resource, resource[:resource_fields])
      collection_resource = CollectionResource.find(collection_resource.id)
      collection_resource.reindex_collection_resource
      collection_resource
    end

    def manage_resource_import(collection_resource, resource_fields, _overwrite = true)
      resource_description_value = collection_resource.resource_description_value
      resource_description_value = ResourceDescriptionValue.create(collection_resource_id: collection_resource.id, resource_field_values: nil) unless resource_description_value.present?
      if resource_fields.present?
        resource_fields.each do |resource_field, _resource_field_values|
          resource_description_value.resource_field_values ||= {}
          resource_description_value.resource_field_values[resource_field.to_s] = {}
        end
        if collection_resource.present?
          resource_fields.each do |resource_field, resource_field_values|
            next if resource_field.to_s == 'duration'
            row = check_dynamic_field_value(resource_field.to_s, resource_field_values, collection_resource, resource_description_value)
            resource_description_value = row if row.present?
          end
        end
      end
      resource_description_value.save if resource_description_value.present?
      resource_description_value
    end

    def check_dynamic_field_value(system_name, resource_field_values, collection_resource, resource_description_value, overwrite = false)
      collection = collection_resource.collection

      org_fields_manager = Aviary::FieldManagement::OrganizationFieldManager.new
      organization = collection_resource.collection.organization
      field_collection_settings = org_fields_manager.organization_field_settings(organization, system_name, 'resource_fields')
      if field_collection_settings.blank?
        org_fields_manager.update_create_field(collection.organization, 'resource_fields', system_name, system_name.to_s.titleize.strip)
        field_collection_settings = org_fields_manager.organization_field_settings(organization, system_name, 'resource_fields')
      end

      field_settings = Aviary::FieldManagement::FieldManager.new(field_collection_settings, system_name)
      return nil if field_settings.field_configuration.present? && field_settings.field_configuration['special_purpose'].present?

      collection_resource_fields = Aviary::FieldManagement::CollectionFieldManager.new.collection_resource_field_settings(collection, 'resource_fields')
      collection_resource_fields['resource_fields'][system_name] = {} unless collection_resource_fields['resource_fields'][system_name].present?
      resource_description_value.resource_field_values ||= {}
      resource_description_value.resource_field_values[system_name] ||= {}
      resource_description_value.resource_field_values[system_name]['values'] ||= []
      resource_field_values.each do |field_value, _|
        if field_value[:vocabulary].present?
          field_collection_settings ||= {}
          field_collection_settings['vocabulary'] ||= []
          field_collection_settings['vocabulary'] << field_value[:vocabulary]
          field_collection_settings['vocabulary'].uniq!
          field_collection_settings['is_vocabulary'] = true
        end
        resource_description_value.resource_field_values[system_name]['values'] ||= []
        if field_value[:value].present? && field_value[:value] != '[TRUNCATE]'
          value = field_value[:value]
          if overwrite
            resource_description_value.resource_field_values[system_name]['values'] = [{ value: value.to_s.strip, vocab_value: field_value[:vocabulary].to_s.strip }]
          else
            resource_description_value.resource_field_values[system_name]['values'] << { value: value.to_s.strip, vocab_value: field_value[:vocabulary].to_s.strip }
          end
        elsif field_value[:value] == '[TRUNCATE]'
          resource_description_value.resource_field_values[system_name]['values'] = []
        end
        resource_description_value.resource_field_values[system_name]['system_name'] = system_name
      end

      update_information = { '0' => field_collection_settings }
      org_fields_manager.update_field_settings(org_fields_manager.organization_field_settings(organization, nil, 'resource_fields', 'sort_order'), update_information, organization, 'resource_fields')
      resource_description_value
    end

    # Method to create a new file_index and its index point.
    # If it failed in the process then it will destroy the index
    def create_file_index(index_param, resource_file)
      return if resource_file.nil?
      index = resource_file.file_indexes.build(index_param)
      begin
        if index.valid?
          index.save
          Aviary::IndexTranscriptManager::IndexManager.new.process(index)
          index.destroy if index.file_index_points.length.zero?
        end
      rescue StandardError => e
        index.destroy if index.present?
        Rails.logger.error e
      end
      index
    end

    # Method to create a new file_transcript and its transcript point.
    # If it failed in the process then it will destroy the transcript
    def create_file_transcript(transcript_param, resource_file, ignore_title = false)
      return if resource_file.nil?
      transcript = resource_file.file_transcripts.build(transcript_param)
      begin
        if transcript.valid?
          transcript.save
          result = Aviary::IndexTranscriptManager::TranscriptManager.new.process(transcript, ignore_title)
          transcript.destroy if result.failure?
        end
      rescue StandardError => e
        transcript.destroy if transcript.present?
        Rails.logger.error e
      end
      transcript
    end

    def create_resource_file(resource, collection_resource, ohms_import = false)
      return if resource[:resource_file].nil? || (resource[:resource_file][:host][:value].casecmp('aviary').zero? && resource[:resource_file][:link][:value].include?('<code>'))
      resource_file = resource[:resource_file]
      sort_order = collection_resource.collection_resource_files.length + 1
      collection_resource_file = nil
      access_file = resource[:file].permission_of_element_private('media_files') ? CollectionResourceFile.accesses[:no] : CollectionResourceFile.accesses[:yes]

      if %w[vimeo soundcloud youtube avalon].include?(resource_file[:host][:value].downcase)
        embed_or_url = ''
        embed_or_url = resource[:resource_file][:embed_code][:value] if resource[:resource_file][:embed_code].present?
        embed_or_url = resource[:resource_file][:link][:value] unless embed_or_url.present?
        embed_name = resource_file[:host][:value].humanize
        target_domain = resource[:resource_file][:target_domain].present? ? resource[:resource_file][:target_domain][:value] : ''

        video_metadata = embed_or_url.present? ? Aviary::ExtractVideoMetadata::VideoEmbed.new(embed_name, embed_or_url).metadata : nil

        if video_metadata
          thumbnail = video_metadata['thumbnail'].present? ? open(video_metadata['thumbnail'], allow_redirections: :all) : ''
          title = video_metadata['title'].present? ? video_metadata['title'] : resource[:title]
          collection_resource_file = collection_resource.collection_resource_files.create(embed_code: video_metadata['url'],
                                                                                          embed_type: CollectionResourceFile::PlayerType::NAME_HUMANIZE.invert[embed_name],
                                                                                          target_domain: target_domain,
                                                                                          resource_file_file_name: title,
                                                                                          embed_content_type: video_metadata['content_type'],
                                                                                          thumbnail: thumbnail,
                                                                                          duration: video_metadata['duration'],
                                                                                          sort_order: sort_order,
                                                                                          access: access_file)
          Aviary::YoutubeCC.new.check_and_extract(collection_resource_file) if embed_name == 'Youtube'
        end
      elsif resource_file[:host][:value].casecmp('aviary').zero?
        resource_file = CollectionResourceFile.find_by(id: resource[:resource_file][:link][:media_id])
        collection_resource_file = check_file_valid(resource_file)
      elsif resource[:resource_file][:link].present?
        embed_or_url = resource[:resource_file][:link][:value]

        if ohms_import
          file_manager = Aviary::FileManager.new
          base_path = Rails.root.join('ohms_import').to_s
          FileUtils.mkdir_p(base_path)
          local_temp_file = file_manager.create_file(base_path, embed_or_url, nil)
          resource_file = collection_resource.collection_resource_files.create(resource_file: open(local_temp_file), sort_order: sort_order, access: access_file)
          file_manager.delete_file(local_temp_file)
        else
          resource_file = collection_resource.collection_resource_files.create(resource_file: open(embed_or_url), sort_order: sort_order, access: access_file)
        end

        collection_resource_file = check_file_valid(resource_file)
      end
      collection_resource_file
    end

    def check_file_valid(resource_file)
      resource_file.valid? ? resource_file : nil
    end

    def extract_data(import)
      base_path = Rails.root.join('extracts', import.id.to_s).to_s
      zip_package = import.import_files.where(file_type: ImportFile::FileType::ZIP_PACKAGE).first
      if zip_package.present?
        file_path = zip_package.associated_file.path
        if ENV['RAILS_ENV'] == 'production'
          FileUtils.mkdir_p(base_path)
          uri = URI.parse(zip_package.associated_file.url)
          file_name = File.basename(uri.path)
          link_to_file = zip_package.associated_file.expiring_url
          system('cd ' + base_path + ' && wget -O ' + file_name + ' "' + link_to_file + '"')
          file_path = "#{base_path}/#{file_name}"
        end
        system('7z x "' + file_path + '" -o' + base_path)
        FileUtils.rm_rf(file_path) if file_path.present? && ENV['RAILS_ENV'] == 'production'
      end
      base_path
    end

    def process(resources, import)
      import.import_error_manager(BulkImportManager.error_reporting('<strong> No valid resource information provided </strong> 0 valid resource find')) unless resources.present?
      if import.import_type == Import::ImportType::OHMS_XML
        process_ohms_package(resources, import)
      elsif import.import_type == Import::ImportType::DIP_PACKAGE
        process_dip_package(resources, import)
      else
        process_aviary_package(resources, import)
      end
    end

    def sync_single_resource_file(resource, import, collection_resource, ohms_import = false)
      collection_resource_file = create_resource_file(resource, collection_resource, ohms_import) if collection_resource.present?
      import.import_error_manager(BulkImportManager.error_reporting("<strong>Invalid media file provided.</strong> #{resource[:resource_file]}")) unless collection_resource_file.present?
      if resource[:index].present? && collection_resource_file.present?
        file_index = { title: File.basename(resource[:file].associated_file_file_name),
                       is_public: !resource[:file].permission_of_element_private('indexes'),
                       language: 'en',
                       associated_file: resource[:file].associated_file,
                       sort_order: collection_resource_file.file_indexes.length + 1,
                       user: import.organization.user }
        index = create_file_index(file_index, collection_resource_file)
        import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process index file #{resource[:file].associated_file_file_name} </strong> #{e}")) unless index.try(:id).present?
      end
      return unless resource[:transcript].present? && collection_resource_file.present?
      file_transcript = { title: File.basename(resource[:file].associated_file_file_name),
                          is_public: !resource[:file].permission_of_element_private('transcripts'),
                          language: 'en',
                          associated_file: resource[:file].associated_file,
                          sort_order: collection_resource_file.file_transcripts.length + 1,
                          user: import.organization.user }
      transcript = create_file_transcript(file_transcript, collection_resource_file)
      import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process transcript file #{resource[:file].associated_file_file_name} </strong> #{e}")) unless transcript.try(:id).present?
    end

    def process_ohms_package(resources, import)
      resource_limit_flag = false
      resources.each_with_index do |resource, _index|
        if import.organization.resource_count >= import.organization.subscription.plan.max_resources
          import.import_error_manager(BulkImportManager.error_reporting("<strong>Resource cannot be synced. Organization resource limit reached. </strong> could not sync resource #{resource[:title]}"))
          resource_limit_flag = true
          next
        end
        collection_resource = create_resource_and_description(resource, import)
        begin
          sync_single_resource_file(resource, import, collection_resource, true)
        rescue StandardError => e
          import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process media file for #{collection_resource.title} </strong> #{e}"))
          Rails.logger.error e
        end
      end

      import.save if import.errors_list.present? && resource_limit_flag
      raise 'Resource cannot be synced. Organization resource limit reached. Sync Failed!' if resource_limit_flag
    end

    def process_dip_package(resources, import)
      resource_limit_flag = false
      resources.each do |resource_value|
        if import.organization.resource_count >= import.organization.subscription.plan.max_resources
          import.import_error_manager(BulkImportManager.error_reporting("<strong>Resource cannot be synced. Organization resource limit reached. </strong> could not sync resource  #{resource_value[:title]}"))
          resource_limit_flag = true
          next
        end
        collection_resource = create_resource_and_description(resource_value, import)
        sort_order = collection_resource.collection_resource_files.length + 1
        resource_value[:resource_file].each do |resource_file|
          file = {
            resource_file: File.new(resource_file[:path]),
            sort_order: sort_order, access: CollectionResourceFile.accesses[:no]
          }
          file[:thumbnail] = File.new(resource_file[:thumb][:path]) if resource_file[:thumb].present?
          collection_resource.collection_resource_files.create(file)
          sort_order += 1
        end
      end

      import.save if import.errors_list.present? && resource_limit_flag
      raise 'Resource cannot be synced. Organization resource limit reached. Sync Failed!' if resource_limit_flag
    end

    def process_aviary_package(resources, import)
      base_path = extract_data(import)
      resource_limit_flag = false
      resources.each do |key, resource_value|
        next unless key.present?
        if import.organization.resource_count >= import.organization.subscription.plan.max_resources
          import.import_error_manager(BulkImportManager.error_reporting("<strong>Resource cannot be synced. Organization resource limit reached. </strong> could not sync resource  #{resource_value[:title]}"))
          resource_limit_flag = true
          next
        end
        collection_resource = create_resource_and_description(resource_value, import)
        unless collection_resource.present?
          import.import_error_manager(BulkImportManager.error_reporting("<strong> skipping resource because of invalid information provided</strong> #{resource_value[:id]} #{resource_value[:title]}"))
          next
        end
        sort_order = collection_resource.collection_resource_files.length + 1
        if resource_value[:resource_file].present?
          resource_value[:resource_file].each do |_, resource_file|
            collection_resource_file = nil
            thumbnail = ''
            begin
              if resource_file[:thumbnail_url].present?
                thumbnail = open(resource_file[:thumbnail_url][:value])
              elsif resource_file[:thumbnail_path].present?
                thumbnail = File.new(base_path + resource_file[:thumbnail_path][:value])
              end
            rescue StandardError => ex
              import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process this file </strong> #{resource_file[:thumbnail_url]} #{resource_file[:thumbnail_path]} #{ex}"))
            end

            is_3d = resource_file[:is_3d].present? ? resource_file[:is_3d][:value] : false
            if resource_file[:path].present?
              begin
                resource_file_obj = collection_resource.collection_resource_files.create(resource_file: File.new(base_path + resource_file[:path][:value]),
                                                                                         thumbnail: thumbnail, sort_order: sort_order, is_3d: is_3d,
                                                                                         access: resource_file.key?(:access) ? resource_file[:access][:value] : CollectionResourceFile.accesses[:no])
                collection_resource_file = check_file_valid(resource_file_obj)
              rescue StandardError
                import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process media </strong> #{resource_file[:path][:value]}"))
              end
            elsif resource_file[:link].present?
              begin
                resource_file_obj = collection_resource.collection_resource_files.create(resource_file: open(resource_file[:link][:value]), is_3d: is_3d,
                                                                                         thumbnail: thumbnail, sort_order: sort_order, access: resource_file[:access][:value])
                collection_resource_file = check_file_valid(resource_file_obj)
              rescue StandardError
                import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process media </strong> #{resource_file[:link][:value]}"))
                next
              end

            elsif resource_file[:embed_code].present? && ['vimeo', 'soundcloud', 'youtube', 'avalon', 'local media server'].include?(resource_file[:host][:value].downcase)
              embed_name = resource_file[:host][:value].humanize
              embed_name = 'Local Media Server' if embed_name.include?('media')
              target_domain = resource_file[:target_domain].present? ? resource_file[:target_domain][:value] : ''
              sleep 2
              begin
                if embed_name.eql?('Local Media Server') && resource_file[:duration].present? && !resource_file[:duration][:value].include?('<code>')
                  params = {
                    duration: resource_file[:duration][:value],
                    thumbnail: thumbnail
                  }
                  video_metadata = Aviary::ExtractVideoMetadata::VideoEmbed.new(embed_name, resource_file[:embed_code][:value], params).metadata
                elsif !embed_name.eql?('Local Media Server')
                  video_metadata = Aviary::ExtractVideoMetadata::VideoEmbed.new(embed_name, resource_file[:embed_code][:value]).metadata
                end
              rescue StandardError
                import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process media from #{embed_name} </strong> #{resource_file[:embed_code][:value]}"))
                next
              end

              if video_metadata
                if thumbnail == ''
                  thumbnail = video_metadata['thumbnail'].present? ? open(video_metadata['thumbnail']) : ''
                end
                title = video_metadata['title'].present? ? video_metadata['title'] : collection_resource[:title]
                begin
                  collection_resource_file = manage_aviary_package_file(collection_resource, video_metadata, embed_name, thumbnail, sort_order, resource_file, title, target_domain)
                  Aviary::YoutubeCC.new.check_and_extract(collection_resource_file) if embed_name == 'Youtube'
                rescue StandardError
                  import.import_error_manager(BulkImportManager.error_reporting("<strong> Unable to process media </strong> #{resource_file[:embed_code]}"))
                  next
                end
              end
            end
            sort_order += 1
            if resource_file[:index].present? && collection_resource_file.present?
              sort_order_index = collection_resource_file.file_indexes.length + 1
              resource_file[:index].each do |index|
                name = index[:title].present? ? index[:title] : File.basename(index[:path])
                language = languages_array_simple[0].key(index[:language])
                language.nil? ? 'en' : language
                file_index = { title: name,
                               language: language,
                               associated_file: File.new(base_path + index[:path]),
                               sort_order: sort_order_index,
                               user: import.organization.user,
                               is_public: index[:is_public],
                               description: index[:description] }
                index = create_file_index(file_index, collection_resource_file)
                sort_order_index += 1 if index.present?
              end
            end
            if resource_file[:transcript].present? && collection_resource_file.present?
              sort_order_transcript = collection_resource_file.file_transcripts.length + 1
              resource_file[:transcript].each do |transcript|
                language = languages_array_simple[0].key(transcript[:language])
                language.nil? ? 'en' : language
                file_transcript = { title: transcript[:title].present? ? transcript[:title] : File.basename(transcript[:path]), language: language, associated_file: File.new(base_path + transcript[:path]),
                                    sort_order: sort_order_transcript, user: import.organization.user, is_public: transcript[:is_public], is_caption: transcript[:is_caption], description: transcript[:description] }
                ignore_title = transcript[:ignore_title]
                transcript = create_file_transcript(file_transcript, collection_resource_file, ignore_title)
                sort_order_transcript += 1 if transcript.present?
              end
            end
          end
        end
      end
      import.save if import.errors_list.present? && resource_limit_flag
      raise 'Resource cannot be synced. Organization resource limit reached. Sync Failed!' if resource_limit_flag
      FileUtils.rm_rf(base_path) if base_path.present?
    end

    def manage_aviary_package_file(collection_resource, video_metadata, embed_name, thumbnail, sort_order, resource_file, title, target_domain)
      collection_resource.collection_resource_files.create(embed_code: video_metadata['url'],
                                                           embed_type: CollectionResourceFile::PlayerType::NAMES.invert[embed_name],
                                                           target_domain: target_domain, resource_file_file_name: title, embed_content_type: video_metadata['content_type'],
                                                           thumbnail: thumbnail, duration: video_metadata['duration'],
                                                           sort_order: sort_order, access: resource_file[:access][:value])
    end

    def api_response(current_organization, resource_id)
      resources, media = CollectionResource.list_collection_resources(nil, resource_id, 1, 0)
      response_body = {}
      resources.each do |resource|
        media_file_ids = []
        unless media.blank?
          media_file_ids = media.map { |id| id['collection_resource_id_ss'].to_i == resource['id_is'] ? id['id_is'] : '' }.uniq.reject(&:blank?)
        end
        metadata = []
        collection_resource = CollectionResource.find(resource['id_is'])
        org_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
        collection_field_manager = Aviary::FieldManagement::CollectionFieldManager.new
        resource_fields_settings = org_field_manager.organization_field_settings(current_organization, nil, 'resource_fields')
        resource_columns_collection = collection_field_manager.sort_fields(collection_field_manager.collection_resource_field_settings(collection_resource.collection, 'resource_fields').resource_fields, 'sort_order')
        resource_description_value = collection_resource.resource_description_value

        resource_columns_collection.each_with_index do |(system_name, single_collection_field), _index|
          next if single_collection_field['field_configuration'].present? && single_collection_field['field_configuration']['special_purpose'].present? && single_collection_field['field_configuration']['special_purpose'].to_s.to_boolean?
          next if resource_fields_settings[system_name].blank? || system_name.blank?
          field_settings = Aviary::FieldManagement::FieldManager.new(resource_fields_settings[system_name], system_name)
          label = field_settings.label
          next if label == 'Title'
          if field_settings.should_display_on_detail_page && single_collection_field['status'].to_s.to_boolean? && resource_description_value.present?
            resource_field_values = resource_description_value.resource_field_values
            if resource_field_values.present? && resource_field_values[system_name].present? && !resource_field_values[system_name].empty? && resource_field_values[system_name]['values'].present?
              field_settings = field_settings
              system_name = system_name
              values = resource_field_values[system_name]
              values_all = []
              if values.present? && values['values'].present?
                values['values'].each do |single_value|
                  next if single_value.class.name != 'Hash'
                  unless single_value['value'].to_s.strip.blank?
                    vocab = single_value['vocab_value']
                    value = single_value['value']
                    vocab = languages_array_simple[0][single_value['value']].present? ? languages_array_simple[0][single_value['value']].html_safe : single_value['value'] if field_settings.label == 'language'
                    values_all << { value: value, vocabulary: vocab }
                  end
                end
                metadata << { label: label, data: values_all } if values_all.present?
              end
            end
          end
        end

        domain_handler = Utilities::AviaryDomainHandler.subdomain_handler(current_organization)
        response_body = {
          id: resource['id_is'],
          title: resource['title_ss'],
          access: CollectionResource.find(resource['id_is']).access.to_s.gsub('access_', ''),
          is_featured: resource['is_featured_bs'],
          media_file_id: media_file_ids,
          media_files_count: resource['resource_file_count_ss'].to_i,
          transcripts_count: resource['transcripts_count_ss'].to_i,
          indexes_count: resource['indexes_count_ss'].to_i,
          metadata: metadata,
          persistent_url: noid_url(noid: resource['noid_ss'], host: domain_handler),
          direct_url: collection_collection_resource_url(collection_id: resource['collection_id_is'], id: resource['id_is'], host: domain_handler),
          created_at: resource['created_at_ss'],
          updated_at: resource['updated_at_ss']
        }
      end
      response_body
    end
  end
end
