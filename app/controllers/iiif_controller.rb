# Collection Resources Controller
class IiifController < ApplicationController
  # after_action :set_content_type

  def manifest
    organization = current_organization

    @collection_resource = CollectionResource.includes(:collection).joins(:collection).where(noid: params[:noid]).where(collections: { organization_id: organization.id }).first
    if @collection_resource.nil?
      render json: { error: 'Not found' }, status: 404
    else
      authorize! :read, @collection_resource

      iiif_hash = {}
      iiif_hash['@context'] = 'http://iiif.io/api/presentation/3/context.json'
      iiif_hash['id'] = iiif_manifest_url(@collection_resource.noid)
      iiif_hash['type'] = 'Manifest'
      iiif_hash['label'] = { en: [@collection_resource.title] }
      iiif_hash['metadata'] = []
      descriptions = []
      right_statements = []
      org_field_manager = Aviary::FieldManagement::OrganizationFieldManager.new
      collection_field_manager = Aviary::FieldManagement::CollectionFieldManager.new
      resource_fields_settings = org_field_manager.organization_field_settings(current_organization, nil, 'resource_fields')
      resource_columns_collection = collection_field_manager.sort_fields(collection_field_manager.collection_resource_field_settings(@collection_resource.collection, 'resource_fields').resource_fields, 'sort_order')
      resource_description_value = @collection_resource.resource_description_value
      resource_columns_collection.each_with_index do |(system_name, single_collection_field), _index|
        next if single_collection_field['field_configuration'].present? && single_collection_field['field_configuration']['special_purpose'].present? && single_collection_field['field_configuration']['special_purpose'].to_s.to_boolean?
        next if resource_fields_settings[system_name].blank? || system_name.blank?
        field_settings = Aviary::FieldManagement::FieldManager.new(resource_fields_settings[system_name], system_name)
        label = field_settings.label
        next if label == 'Title'

        if field_settings.should_display_on_detail_page && single_collection_field['status'].to_s.to_boolean? && resource_description_value.present?
          resource_field_values = resource_description_value.resource_field_values
          if resource_field_values.present? && resource_field_values[system_name].present? && !resource_field_values[system_name].empty? && resource_field_values[system_name]['values'].present?
            system_name = system_name
            values = resource_field_values[system_name]
            values_all = []
            if values.present? && values['values'].present?
              values['values'].each do |single_value|
                next if single_value.class.name != 'Hash'
                unless single_value['value'].to_s.strip.blank?
                  vocab = single_value['vocab_value']
                  value = single_value['value']
                  final_value = Rails::Html::WhiteListSanitizer.new.sanitize(value, tags: %w(a b br i p img small span sub sup))
                  final_value = time_to_duration(value) if system_name.to_s == 'duration'
                  final_value += " (#{vocab})" if vocab.present?
                  values_all << final_value
                  descriptions << value if system_name.to_s == 'description'
                  right_statements << value if system_name.to_s == 'rights_statement'
                end
              end
              iiif_hash['metadata'] << { label: { en: [label] }, value: { en: values_all } } if values.present?
            end
          end
        end
      end

      iiif_hash['summary'] = { en: descriptions } if descriptions.present?

      iiif_hash['requiredStatement'] = { label: { en: ['Attribution'] }, value: { en: right_statements } } if right_statements.present?
      org_logo = {}
      org_logo['id'] = organization.logo_image.url
      org_logo['type'] = 'Image'
      iiif_hash['provider'] = [
        {
          id: org_aboutus_url,
          type: 'Agent',
          label: { en: [organization.name] },
          homepage: [{
                       id: root_url,
                       type: 'Text',
                       label: { en: [organization.name] },
                       format: 'text/html'

                     }],
          logo: [org_logo]
        }
      ]
      iiif_hash['thumbnail'] = []

      iiif_hash['items'] = []
      media_files = @collection_resource.collection_resource_files.order_file.where(access: true)
      if media_files.try(:first).present?
        first_media_file = media_files.try(:first)
        content_type = first_media_file.thumbnail.try(:content_type).present? ? first_media_file.thumbnail.content_type : 'image/png'
        iiif_hash['thumbnail'] << { id: first_media_file.thumbnail_image, type: 'Image', format: content_type }
      end
      media_files.each_with_index do |media_file, index|
        content_type = media_file.thumbnail.try(:content_type).present? ? media_file.thumbnail.content_type : 'image/png'
        media_url = collection_collection_resource_details_url(@collection_resource.collection, @collection_resource, media_file)
        count = index + 1

        iiif_hash['items'] << {
          id: media_url,
          type: 'Canvas',
          label: { en: ["Media File #{count} of #{media_files.count}"] },
          duration: media_file.duration.to_f,
          thumbnail: [{ id: media_file.thumbnail_image, type: 'Image', format: content_type }],
          items: [{ id: media_url + '/content/1', type: 'AnnotationPage', items: [{
                                                                                    id: media_url + "/content/#{count}/annotation/1",
                                                                                    type: 'Annotation',
                                                                                    motivation: ['painting'],
                                                                                    body: {
                                                                                      id: media_file.media_direct_url,
                                                                                      type: media_file.media_content_type.include?('video') ? 'Video' : 'Audio',
                                                                                      format: media_file.media_content_type,
                                                                                      duration: media_file.duration.to_f
                                                                                    },
                                                                                    target: media_url
                                                                                  }] }],
          annotations: annotations(media_file, media_url)
        }
      end
      render json: iiif_hash
    end
  end

  def set_content_type
    self.content_type = 'application/ld+json; charset=utf-8'
  end

  private

  def annotations(media_file, media_url)
    annotations = []
    counter = 1
    annotation_counter = 1
    media_file.file_transcripts.each do |transcript|
      points = []
      transcript_points = transcript.file_transcript_points
      transcript_points.each do |point|
        text = point.speaker.present? ? "#{point.speaker}: #{point.text}" : point.text
        points << {
          id: "#{media_url}/transcript/#{transcript.id}/annotation/#{annotation_counter}",
          type: 'Annotation',
          motivation: %w[supplementing transcribing],
          body: {
            type: 'TextualBody',
            value: text,
            format: 'text/plain'
          },
          target: {
            source: "#{media_url}##{point.start_time.to_f},#{point.end_time.to_f}",
            # selector: { type: 'RangeSelector', startSelector: { type: 'PointSelector', t: point.start_time.to_f }, endSelector: { type: 'PointSelector', t: point.end_time.to_f } }
          }
        }
        annotation_counter += 1
      end
      annotations << { id: media_url + "/transcript/#{transcript.id}", type: 'AnnotationPage', label: { en: [transcript.title] }, items: points }
      counter += 1
    end
    media_file.file_indexes.public_index.each do |single_index|
      points = []
      index_points = single_index.file_index_points
      index_fields = { title: 'Title', synopsis: 'Synopsis', partial_script: 'Partial transcript', subjects: 'Subject', keywords: 'Keyword' }

      index_points.each do |point|
        index_fields.each do |field|
          field_name, display_name = field
          next unless point.try(field_name).present?
          body = []
          if %w[Subject Keyword].include?(display_name)
            split_field_content = point.try(field_name).split(';')
            split_field_content.each do |field_content|
              body << {
                type: 'TextualBody',
                value: field_content.strip,
                format: 'text/plain'
              }
            end
          else
            body << {
              type: 'TextualBody',
              value: point.try(field_name),
              format: 'text/plain'
            }
          end
          points << {
            id: "#{media_url}/index/#{single_index.id}/annotation/#{annotation_counter}",
            type: 'Annotation',
            motivation: %w[supplementing describing],
            body: body,
            target: {
              source: "#{media_url}##{point.start_time.to_f},#{point.end_time.to_f}"
            }
          }
          annotation_counter += 1
        end
      end
      annotations << { id: media_url + "/index/#{single_index.id}", type: 'AnnotationPage', label: { en: [single_index.title] }, items: points }
      counter += 1
    end
    annotations
  end
end
