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
      @dynamic_fields = @collection_resource.all_fields

      iiif_hash = {}
      iiif_hash['@context'] = 'http://iiif.io/api/presentation/3/context.json'
      iiif_hash['id'] = iiif_manifest_url(@collection_resource.noid)
      iiif_hash['type'] = 'Manifest'
      iiif_hash['label'] = { en: [@collection_resource.title] }
      iiif_hash['metadata'] = []
      descriptions = []
      right_statements = []
      @dynamic_fields['CollectionResource'].each do |field|
        values = []
        field['values'].each do |value|
          next unless value['value'].present?
          final_value = Rails::Html::WhiteListSanitizer.new.sanitize(value['value'], tags: %w(a b br i p img small span sub sup))
          final_value = time_to_duration(value['value']) if field['field'].system_name == 'duration'
          final_value += " (#{value['vocab_value']})" if value['vocab_value'].present?
          values << final_value
          descriptions << value['value'] if field['field'].system_name == 'description'
          right_statements << value['value'] if field['field'].system_name == 'rights_statement'
        end
        iiif_hash['metadata'] << { label: { en: [field['field'].label] }, value: { en: values } } if values.present?
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
            source: media_url.to_s,
            selector: { type: 'RangeSelector', startSelector: { type: 'PointSelector', t: point.start_time.to_f }, endSelector: { type: 'PointSelector', t: point.end_time.to_f } }
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
              source: media_url.to_s,
              selector: { type: 'RangeSelector', startSelector: { type: 'PointSelector', t: point.start_time.to_f }, endSelector: { type: 'PointSelector', t: point.end_time.to_f } }
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
