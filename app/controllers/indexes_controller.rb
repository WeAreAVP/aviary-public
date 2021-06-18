# controllers/indexes_controllers.rb
#
# IndexesController
# The module is written to store the index and transcript for the collection resource file
# Currently supports OHMS XML and WebVtt format
# Nokogiri, webvtt-ruby gem is needed to run this module successfully
# dry-transaction gem is needed for adding transcript steps to this process
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class IndexesController < ApplicationController
  before_action :authenticate_user!
  def index
    authorize! :manage, current_organization
    session[:file_index_bulk_edit] = []
    respond_to do |format|
      format.html
      format.json { render json: IndexesDatatable.new(view_context, current_organization, params['called_from'], params[:additionalData]) }
    end
  end

  def bulk_file_index_edit
    respond_to do |format|
      format.html
      if params['check_type'] == 'bulk_delete'
        FileIndex.where(id: session[:file_index_bulk_edit]).each(&:destroy)
      elsif params['check_type'] == 'change_status'
        FileIndex.where(id: session[:file_index_bulk_edit]).each do |index|
          index.update(is_public: params['access_type'] == 'yes')
        end
      end
      render json: { message: t('updated_successfully'),
                     errors: false,
                     status: 'success',
                     action: 'bulk_file_index_edit' }
    end
  end

  def create
    if params[:file_index_id]
      file_index = FileIndex.find(params[:file_index_id])
      success = file_index.update(file_index_params)
    else
      file_index = FileIndex.new(file_index_params)
      file_index.user = current_user
      resource_file = CollectionResourceFile.find(params[:resource_file_id])
      file_index.collection_resource_file = resource_file
      file_index.sort_order = resource_file.file_indexes.length + 1
      success = file_index.save
    end
    respond_to do |format|
      if success
        file_index.file_index_points.destroy_all if params[:file_index_id] && file_index_params[:associated_file].present?
        Aviary::IndexTranscriptManager::IndexManager.new.process(file_index) if file_index_params[:associated_file].present?
        format.json { render json: [errors: []] }
      else
        format.json { render json: [errors: file_index.errors] }
      end
    end
  end

  def sort
    unless params[:sort_list].nil?
      params[:sort_list].each_with_index do |id, index|
        FileIndex.where(id: id).update_all(sort_order: index + 1)
      end
    end
    respond_to do |format|
      format.json { render json: [errors: []] }
    end
  end

  def destroy
    file_index = FileIndex.find(params[:id])
    file_index.destroy
    flash[:notice] = 'Index was successfully deleted.'
    redirect_back(fallback_location: root_path)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def file_index_params
    params.require(:file_index).permit(:title, :associated_file, :is_public, :language, :description)
  end
end
