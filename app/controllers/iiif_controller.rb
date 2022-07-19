# Collection Resources Controller
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class IiifController < ApplicationController
  # after_action :set_content_type

  def manifest
    headers['Access-Control-Allow-Origin'] = '*'
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
      iiif_hash['logo'] = organization.logo_image.url
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
                  final_value = Rails::Html::WhiteListSanitizer.new.sanitize(value, tags: %w(a b br i p img small span sub sup em strong))
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
        media_type = media_file.media_content_type.include?('video') ? 'Video' : 'Audio'
        width = 640
        height = @collection_resource.collection.is_audio_only && media_type == 'Audio' ? 40 : 360
        metadata = media_file.is_3d? ? [{ label: { en: ['360 Video'] }, value: { en: ['TRUE'] } }] : []
        iiif_hash['items'] << {
          id: media_url,
          type: 'Canvas',
          label: { en: ["Media File #{count} of #{media_files.count} - #{media_file.resource_file_file_name}"] },
          duration: media_file.duration.to_f,
          width: width,
          height: height,
          thumbnail: [{ id: media_file.thumbnail_image, type: 'Image', format: content_type }],
          items: [{ id: media_url + '/content/1', type: 'AnnotationPage',
                    items: [{
                      id: media_url + "/content/#{count}/annotation/1",
                      type: 'Annotation',
                      motivation: 'painting',
                      body: {
                        id: media_file.media_direct_url,
                        type: media_type,
                        format: media_file.media_content_type,
                        duration: media_file.duration.to_f,
                        width: width,
                        height: height
                      },
                      target: media_url,
                      metadata: metadata
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
    media_file.file_transcripts.public_transcript.each do |transcript|
      points = []
      transcript_points = transcript.file_transcript_points
      transcript_points.each do |point|
        text = point.speaker.present? ? "<strong>#{point.speaker}:</strong> #{point.text}" : point.text
        points << {
          id: "#{media_url}/transcript/#{transcript.id}/annotation/#{annotation_counter}",
          type: 'Annotation',
          motivation: 'transcribing',
          body: {
            type: 'TextualBody',
            value: text,
            format: 'text/plain'
          },
          target: "#{media_url}#t=#{point.start_time.to_f},#{point.end_time.to_f}"
        }
        annotation_counter += 1
      end
      annotations << { id: media_url + "/transcript/#{transcript.id}", type: 'AnnotationPage', label: { en: [transcript.title] }, items: points }
      counter += 1

      if transcript.is_caption?
        points = [{
          id: "#{media_url}/transcript/#{transcript.id}/annotation/#{annotation_counter}",
          type: 'Annotation',
          motivation: 'subtitling',
          body: {
            type: 'TextualBody',
            value: transcript.associated_file.url,
            format: 'text/vtt',
            language: transcript.language
          },
          target: transcript.associated_file.url
        }]
        annotation_counter += 1
        annotations << { id: media_url + "/transcript/#{transcript.id}", type: 'AnnotationPage', label: { en: [languages_array_simple[0][transcript.language]] }, items: points }
        counter += 1
      end
    end
    media_file.file_transcripts.public_transcript.each do |transcript|
      next unless transcript.annotation_set.present?
      annotation_set = transcript.annotation_set
      next unless annotation_set.is_public
      points = []
      annotation_points = JSON.parse(annotation_set.annotations.to_json)
      annotation_points.each_with_index do |v, i|
        annotation_points[i]['target_info'] = JSON.parse(v['target_info'])
        annotation_points[i]['time'] = annotation_points[i]['target_info']['time']
      end
      annotation_points = annotation_points.sort_by { |a| a['time'].to_f }

      annotation_points.each do |single_annotation|
        target_info = single_annotation['target_info']
        annotation_transcript_point = transcript.file_transcript_points.find(target_info['pointId'])
        points << {
          id: "#{media_url}/annotation_set/#{annotation_set.id}/annotation/#{annotation_counter}",
          type: 'Annotation',
          motivation: 'supplementing',
          body: {
            type: 'TextualBody',
            value: Rails::Html::WhiteListSanitizer.new.sanitize(single_annotation['body_content'], tags: %w(a b br i p small span sub sup em strong)),
            format: 'text/plain'
          },
          target: "#{media_url}#t=#{annotation_transcript_point.start_time.to_f},#{annotation_transcript_point.end_time.to_f}"
        }
        annotation_counter += 1
      end
      annotations << { id: media_url + "/annotation_set/#{transcript.annotation_set.id}", type: 'AnnotationPage', label: { en: [transcript.annotation_set.title] }, items: points }
      counter += 1
    end
    media_file.file_indexes.public_index.each do |single_index|
      points = []
      index_points = single_index.file_index_points
      index_fields = { title: 'Title', synopsis: 'Synopsis', partial_script: 'Partial Transcript', subjects: 'Subjects', keywords: 'Keywords' }

      index_points.each do |point|
        index_fields.each do |field|
          field_name, display_name = field
          next unless point.try(field_name).present?
          body = []
          if %w[Subjects Keywords].include?(display_name)
            split_field_content = point.try(field_name).split(';')
            split_field_content.each do |field_content|
              body << {
                type: 'TextualBody',
                value: field_content.strip,
                format: 'text/plain',
                label: { en: [display_name] }
              }
            end
          else
            body << {
              type: 'TextualBody',
              value: point.try(field_name),
              format: 'text/plain',
              label: { en: [display_name] }
            }
          end
          time = point.start_time == point.end_time ? point.start_time.to_f.to_s : "#{point.start_time.to_f},#{point.end_time.to_f}"
          points << {
            id: "#{media_url}/index/#{single_index.id}/annotation/#{annotation_counter}",
            type: 'Annotation',
            motivation: 'supplementing',
            body: body,
            target: "#{media_url}#t=#{time}"
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
