# controllers/concerns/resource_file_management.rb
# Module Aviary::ResourceFileManagement
# The module is written to store the video or the embed code to the database.
#
# The module requires Aviary::ExtractVideoMetaData Module to successfully complete the process.
#
# Author:: Nouman Tayyab  (mailto:nouman@weareavp.com)
module Aviary::ResourceFileManagement
  extend ActiveSupport::Concern

  def save_resource_file
    store_file_and_metadata(params, @collection_resource)
    respond_to do |format|
      format.html { redirect_to collection_collection_resource_add_resource_file_path(@collection_resource.collection, @collection_resource) }
      format.json { render json: [status: :created, error: flash[:danger] ||= '', message: flash[:notice], location: collection_collection_resource_path(@collection_resource.collection, @collection_resource)] }
    end
  end

  def update_file_name
    @collection_resource.collection_resource_files.find(params[:collection_resource_file_id]).update(file_display_name: params[:collection_resource][:title])
    respond_to do |format|
      format.html { redirect_to collection_collection_resource_add_resource_file_path(@collection_resource.collection, @collection_resource) }
      format.json { render json: { message: t('information_updated') } }
    end
  end

  def show_search_counts
    response = { count_presence: session[:count_presence], description_count: session[:description_count], transcript_count: session[:transcript_count], index_count: session[:index_count] }
    respond_to do |format|
      format.html { render json: response }
      format.json { render json: response }
    end
  end

  def update_thumbnail
    respond_to do |format|
      begin
        update_hash = { access: params[:collection_resource_file][:access] }
        update_hash[:is_downloadable] = params[:collection_resource_file][:is_downloadable]
        update_hash[:download_enabled_for] = params[:collection_resource_file][:download_enabled_for] if params[:collection_resource_file].include? 'download_enabled_for'
        update_hash[:downloadable_duration] = params[:collection_resource_file][:downloadable_till] if params[:collection_resource_file].include? 'downloadable_till'
        unless params[:collection_resource_file][:thumbnail].blank?
          update_hash[:thumbnail] = params[:collection_resource_file][:thumbnail]
        end
        resource_file = @collection_resource.collection_resource_files.find(params[:collection_resource_file_id])
        resource_file.update(update_hash)
        unless params[:collection_resource_file][:replace_DO_thumb].to_i.zero?
          organization_integration = current_organization.organization_integrations.first
          ArchivesSpace::DigitalObject.new(organization_integration).update_do_object(resource_file) if organization_integration.present?
        end
        @msg = t('information_updated')
        flash[:notice] = @msg
        response = 1
      rescue StandardError
        @msg = t('error_update_again')
        flash[:danger] = @msg
        response = 0
      end
      format.html { redirect_to collection_collection_resource_add_resource_file_path(@collection_resource.collection, @collection_resource) }
      format.json { render json: { message: @msg, response: response } }
    end
  end

  private

  def store_file_and_metadata(params, collection_resource)
    sort_order = collection_resource.collection_resource_files.length + 1
    file_successfully_uploaded = t('file_successfully_uploaded')
    if params[:collection_resource].present?
      resource_file_id = params[:collection_resource][:resource_file_id]
      update_sort = params[:collection_resource][:sort_order]
      param_collection_resource = params[:collection_resource]

      if param_collection_resource[:file_url].present?
        return flash[:danger] = 'Not a valid URL' unless param_collection_resource[:file_url] =~ URI::DEFAULT_PARSER.make_regexp
        if resource_file_id.present?
          resource_file = collection_resource.collection_resource_files.where(id: resource_file_id).first
          result = resource_file.update(resource_file: open(param_collection_resource[:file_url], read_timeout: 10), sort_order: update_sort)
          return result ? flash[:notice] = t('information_updated') : flash[:danger] = 'Error updating file.'
        else
          result = collection_resource.collection_resource_files.create(resource_file: open(param_collection_resource[:file_url], read_timeout: 10), sort_order: sort_order)
          return flash[:notice] = file_successfully_uploaded if result.id.present?
          return flash[:danger] = result.errors[:resource_file][0]
        end
      elsif param_collection_resource[:embed_code].present?
        embed_name = CollectionResourceFile.embed_type_name(param_collection_resource[:embed_type].to_i)
        video_metadata = Aviary::ExtractVideoMetadata::VideoEmbed.new(embed_name, param_collection_resource[:embed_code], param_collection_resource).metadata
        return flash[:danger] = t('resource_file_error') unless video_metadata
        thumbnail = video_metadata['thumbnail'].present? ? open(video_metadata['thumbnail'], allow_redirections: :all) : ''

        embed_code_hash = { embed_code: video_metadata['url'], embed_type: param_collection_resource[:embed_type], target_domain: param_collection_resource[:target_domain],
                            resource_file_file_name: video_metadata['title'], embed_content_type: video_metadata['content_type'], thumbnail: thumbnail, duration: video_metadata['duration'] }
        embed_code_hash[:file_display_name] = video_metadata['title'] if param_collection_resource[:embed_type].to_i.zero?
        if resource_file_id.present?
          resource_file = collection_resource.collection_resource_files.where(id: resource_file_id).first
          resource_file.update(embed_code_hash.merge!(sort_order: update_sort)) if resource_file.present?
        else
          resource_file = collection_resource.collection_resource_files.create(embed_code_hash.merge!(sort_order: sort_order))
        end
        Aviary::YoutubeCC.new.check_and_extract(resource_file) if embed_name == 'Youtube'
        flash[:notice] = file_successfully_uploaded
      end
    else
      errors = []
      coll_resource_file = collection_resource.collection_resource_files.where(id: params[:av_resource][:resource_file_id]).first
      if coll_resource_file.present?
        created_file = coll_resource_file.update(resource_file: params[:av_resource][:resource_files], sort_order: params[:av_resource][:resource_file_id], embed_code: '', embed_type: '')

        errors = 'Error updating file.' unless created_file

      else
        params[:av_resource][:resource_files].each do |file|
          created_file = collection_resource.collection_resource_files.create(resource_file: file, sort_order: sort_order)
          unless created_file.errors.messages.empty?
            errors += created_file.errors.messages[:resource_file]
          end
          sort_order += 1
        end
      end
      return flash[:danger] = errors.join(',') if errors.present?
      flash[:notice] = file_successfully_uploaded
    end
  end
end
