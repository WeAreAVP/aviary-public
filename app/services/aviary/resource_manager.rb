# services/aviary/resource_manager.rb
#
# Module Aviary::ResourceManager
# The module is written to map and store the resource related info in the Aviary system
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
# TODO: Need to cleanup this ResourceManager Class
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Aviary
  # ResourceManager Class for managing and mapping the resource information
  class ResourceManager
    PREVIEW_ONLY = 1
    INSERT_ONLY = 2
    include ApplicationHelper
    require 'zip'
    attr_accessor :sync_problem
    # Method to create a new resource and its description fields with values
    def create_resource_and_description(resource, import)
      return if resource[:resource_file].present? && import.import_type == Import::ImportType::OHMS_XML && resource[:resource_file][:host][:value].casecmp('aviary').zero? && resource[:resource_file][:link][:value].include?('<code>')
      is_public = resource[:access]
      is_featured = resource[:is_featured]

      value_custom_unique_identifier = begin
                                         resource[:custom_unique_identifier] = clean_uri(resource[:custom_unique_identifier])
                                       rescue StandardError => e
                                         as_config.logger.fatal "failing setting up custom_unique_identifier #{e}"
                                         ''
                                       end

      custom_unique_identifier = value_custom_unique_identifier.present? ? value_custom_unique_identifier : ''

      if import.import_type == Import::ImportType::OHMS_XML && resource[:resource_file].present? && resource[:resource_file][:host][:value].casecmp('aviary').zero?
        resource_file = CollectionResourceFile.find_by(id: resource[:resource_file][:link][:media_id])
        if import.organization_id == resource_file.collection_resource.collection.organization.id
          collection_resource = resource_file.collection_resource
          update_fields = {}
          update_fields[:access] = is_public if resource[:access]
          update_fields[:title] = resource[:title] if resource[:title]
          update_fields[:is_featured] = is_featured if resource[:is_featured]
          update_fields[:external_resource_id] = import.id
          update_fields[:custom_unique_identifier] = custom_unique_identifier if custom_unique_identifier.present?
          collection_resource.update(update_fields)
        end
      else
        begin
          collection_resource = import.collection.collection_resources.create!(title: resource[:title], access: is_public,
                                                                               is_featured: is_featured, custom_unique_identifier: custom_unique_identifier, external_resource_id: import.id)
        rescue StandardError
          collection_resource = import.collection.collection_resources.create(title: resource[:title], access: is_public,
                                                                              is_featured: is_featured, custom_unique_identifier: '', external_resource_id: import.id)
        end
      end
      if collection_resource.present?
        collection_resource_fields = collection_resource.dynamic_attributes
        field_values = []
        resource[:resource_fields].each do |resource_field, resource_field_values|
          row = check_dynamic_field_value(import.collection, collection_resource_fields, resource_field.to_s, resource_field_values)
          field_values << row
        end
        collection_resource.batch_update_values(field_values)
      end
      collection_resource
    end

    def check_dynamic_field_value(collection, collection_resource_fields, system_name, resource_field_values)
      row = {
        field_id: nil,
        values: []
      }
      field_index = collection_resource_fields['fields'].index { |hash| hash['system_name'].to_s == system_name.to_s && hash['source_type'].to_s == 'CollectionResource' }
      if !field_index.nil?
        field = collection_resource_fields['fields'][field_index]
        field_id = field.id
      else
        new_field =
          {
            label: system_name.titleize, system_name: system_name.to_s,
            column_type: CustomFields::Field::TypeInformation::TEXT,
            source_type: 'CollectionResource',
            is_custom: true
          }
        field_id = collection.create_update_dynamic(new_field)
      end
      row[:field_id] = field_id
      resource_field_values.each do |field_value, _|
        if field_value[:vocabulary].present?
          CustomFields::Field.create_or_update_vocabularies(field_id, field_value[:vocabulary])
        else
          field_value[:vocabulary] = ''
        end
        value = field_value[:value].present? ? field_value[:value] : ''
        row[:values] << { value: value, vocab_value: field_value[:vocabulary].strip }
      end
      row
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

    def create_resource_file(resource, collection_resource)
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
        resource_file = collection_resource.collection_resource_files.create(resource_file: open(embed_or_url), sort_order: sort_order, access: access_file)
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
      if import.import_type == Import::ImportType::OHMS_XML
        process_ohms_package(resources, import)
      elsif import.import_type == Import::ImportType::DIP_PACKAGE
        process_dip_package(resources, import)
      else
        process_aviary_package(resources, import)
      end
    end

    def sync_single_resource_file(resource, import, collection_resource)
      collection_resource_file = create_resource_file(resource, collection_resource) if collection_resource.present?
      if resource[:index].present? && collection_resource_file.present?
        file_index = { title: File.basename(resource[:file].associated_file_file_name),
                       is_public: !resource[:file].permission_of_element_private('indexes'),
                       language: 'en',
                       associated_file: resource[:file].associated_file,
                       sort_order: collection_resource_file.file_indexes.length + 1,
                       user: import.organization.user }
        create_file_index(file_index, collection_resource_file)
      end
      return unless resource[:transcript].present? && collection_resource_file.present?
      file_transcript = { title: File.basename(resource[:file].associated_file_file_name),
                          is_public: !resource[:file].permission_of_element_private('transcripts'),
                          language: 'en',
                          associated_file: resource[:file].associated_file,
                          sort_order: collection_resource_file.file_transcripts.length + 1,
                          user: import.organization.user }
      create_file_transcript(file_transcript, collection_resource_file)
    end

    def process_ohms_package(resources, import)
      self.sync_problem = []
      resources.each_with_index do |resource, index|
        collection_resource = create_resource_and_description(resource, import)
        begin
          sync_single_resource_file(resource, import, collection_resource)
        rescue StandardError => e
          Rails.logger.error e
          sync_problem[index] = { resource_hash: resource, collection_resource: collection_resource }
        end
      end
      return unless sync_problem.present?
      sync_problem.each do |single_problem_sync|
        begin
          sync_single_resource_file(single_problem_sync[:resource_hash], import, single_problem_sync[:collection_resource])
        rescue StandardError => e
          Rails.logger.error e
        end
      end
    end

    def process_dip_package(resources, import)
      resources.each do |resource_value|
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
    end

    def process_aviary_package(resources, import)
      base_path = extract_data(import)
      resources.each do |_, resource_value|
        collection_resource = create_resource_and_description(resource_value, import)
        sort_order = collection_resource.collection_resource_files.length + 1
        resource_value[:resource_file].each do |_, resource_file|
          collection_resource_file = nil
          thumbnail = ''
          if resource_file[:thumbnail_url].present?
            thumbnail = open(resource_file[:thumbnail_url][:value])
          elsif resource_file[:thumbnail_path].present?
            thumbnail = File.new(base_path + resource_file[:thumbnail_path][:value])
          end
          if resource_file[:path].present?
            resource_file_obj = collection_resource.collection_resource_files.create(resource_file: File.new(base_path + resource_file[:path][:value]),
                                                                                     thumbnail: thumbnail, sort_order: sort_order, access: resource_file.key?(:access) ? resource_file[:access][:value] : CollectionResourceFile.accesses[:no])
            collection_resource_file = check_file_valid(resource_file_obj)
          elsif resource_file[:link].present?
            resource_file_obj = collection_resource.collection_resource_files.create(resource_file: open(resource_file[:link][:value]),
                                                                                     thumbnail: thumbnail, sort_order: sort_order, access: resource_file[:access][:value])
            collection_resource_file = check_file_valid(resource_file_obj)
          elsif resource_file[:embed_code].present? && ['vimeo', 'soundcloud', 'youtube', 'avalon', 'local media server'].include?(resource_file[:host][:value].downcase)
            embed_name = resource_file[:host][:value].humanize
            embed_name = 'Local Media Server' if embed_name.include?('media')
            target_domain = resource_file[:target_domain].present? ? resource_file[:target_domain][:value] : ''
            sleep 2

            if embed_name.eql?('Local Media Server') && resource_file[:duration].present? && !resource_file[:duration][:value].include?('<code>')
              params = {
                duration: resource_file[:duration][:value],
                thumbnail: thumbnail
              }
              video_metadata = Aviary::ExtractVideoMetadata::VideoEmbed.new(embed_name, resource_file[:embed_code][:value], params).metadata
            elsif !embed_name.eql?('Local Media Server')
              video_metadata = Aviary::ExtractVideoMetadata::VideoEmbed.new(embed_name, resource_file[:embed_code][:value]).metadata
            end

            if video_metadata
              if thumbnail == ''
                thumbnail = video_metadata['thumbnail'].present? ? open(video_metadata['thumbnail']) : ''
              end
              title = video_metadata['title'].present? ? video_metadata['title'] : collection_resource[:title]
              collection_resource_file = collection_resource.collection_resource_files.create(embed_code: video_metadata['url'],
                                                                                              embed_type: CollectionResourceFile::PlayerType::NAMES.invert[embed_name],
                                                                                              target_domain: target_domain,
                                                                                              resource_file_file_name: title,
                                                                                              embed_content_type: video_metadata['content_type'],
                                                                                              thumbnail: thumbnail,
                                                                                              duration: video_metadata['duration'],
                                                                                              sort_order: sort_order,
                                                                                              access: resource_file[:access][:value])
              Aviary::YoutubeCC.new.check_and_extract(collection_resource_file) if embed_name == 'Youtube'
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
                             is_public: index[:is_public] }
              index = create_file_index(file_index, collection_resource_file)
              sort_order_index += 1 if index.present?
            end
          end
          if resource_file[:transcript].present? && collection_resource_file.present?
            sort_order_transcript = collection_resource_file.file_transcripts.length + 1
            resource_file[:transcript].each do |transcript|
              language = languages_array_simple[0].key(transcript[:language])
              language.nil? ? 'en' : language
              file_transcript = { title: transcript[:title].present? ? transcript[:title] : File.basename(transcript[:path]),
                                  language: language,
                                  associated_file: File.new(base_path + transcript[:path]),
                                  sort_order: sort_order_transcript,
                                  user: import.organization.user,
                                  is_public: transcript[:is_public],
                                  is_caption: transcript[:is_caption] }
              ignore_title = transcript[:ignore_title]
              transcript = create_file_transcript(file_transcript, collection_resource_file, ignore_title)
              sort_order_transcript += 1 if transcript.present?
            end
          end
        end
      end
      FileUtils.rm_rf(base_path) if base_path.present?
    end
  end
end
