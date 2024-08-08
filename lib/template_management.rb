# TemplateManagement
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class TemplateManagement
  def initialize(params, collection)
    @params = params
    @collection = collection
  end

  def create_custom_fields(field_type, all_params, vocabulary)
    meta_field = CollectionResourceField.find_by(id: @params[:meta_field_id])
    current_params = { is_required: all_params[:is_required], is_public: all_params[:is_visible],
                       is_repeatable: all_params[:is_repeatable], is_visible: all_params[:is_visible],
                       is_tombstone: all_params[:is_tombstone] }

    field_type[:is_vocabulary] = 0
    field_type[:is_vocabulary] = 1 if field_type[:column_type].to_s == FieldType::TypeInformation::DROPDOWN.to_s
    field_type[:system_name] = field_type['label'].parameterize.underscore
    if meta_field.present?
      meta_field.field_type.update(field_type)
      current_params[:field_type] = meta_field.field_type
      current_params[:sort_order] = all_params[:sort_order]

      meta_field.update(current_params)
      CollectionResourceFieldValue.where(vocabularies_id: meta_field.field_type.vocabularies.map(&:id.to_proc))
      Vocabulary.where(field_type: meta_field.field_type).destroy_all
      field = meta_field.field_type
    else
      field = FieldType.create(field_type)
      field.system_name = field.label.parameterize.underscore
      field.save
      current_params[:field_type] = field
      current_params[:sort_order] = 9999
      @collection.collection_resource_fields.create(current_params)
    end

    vocabulary.split(',').each do |value|
      voc = Vocabulary.create(field_type: field, value: value)
      voc.save
    end
    @collection_fields = @collection.collection_resource_fields.order('sort_order ASC')
  end

  def save_field_visibility
    CollectionResourceField.find(@params['field_id']).update(is_visible: @params['is_visible'])
  end

  def save_tombstone_field
    CollectionResourceField.find(@params['field_id']).update(is_tombstone: @params['is_tombstone'])
  end

  def save_custom_field_visibility
    coll_meta_field = CollectionMetaField.find_by(id: @params[:collection_meta_id])
    coll_meta_field.update(is_visible: @params[:is_visible])
  end

  def save_custom_vocabulary(meta_field, custom_vocabularies_params)
    @meta_field = meta_field
    @meta_field.custom_vocabularies.where(collection_id: @collection.id).delete_all
    custom_vocabularies_params.each do |vocabulary|
      @meta_field.custom_vocabularies.create(collection_id: @collection.id, option: vocabulary)
    end
  end
end
