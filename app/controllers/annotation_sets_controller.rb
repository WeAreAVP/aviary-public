# controllers/annotation_sets_controller.rb
#
# AnnotationSetsController
# The class is responsible for managing annotation sets for the collection resource
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class AnnotationSetsController < ApplicationController
  before_action :set_annotation_set, only: %i[edit update destroy]
  before_action :authenticate_user!
  load_and_authorize_resource
  layout false

  # GET /annotation_sets/new
  def new
    @annotation_set = AnnotationSet.new
  end

  # GET /annotation_sets/1/edit
  def edit; end

  # POST /annotation_sets
  # POST /annotation_sets.json
  def create
    object = prepare_field(annotation_set_params)
    @annotation_set = AnnotationSet.new(object)
    file_transcript = FileTranscript.find(params[:transcript].to_i)
    @annotation_set.file_transcript_id = file_transcript.id
    @annotation_set.collection_resource_id = file_transcript.collection_resource_file.collection_resource.id
    @annotation_set.organization = current_organization
    @annotation_set.created_by_id = current_user.id
    respond_to do |format|
      if @annotation_set.save
        format.html { redirect_to annotation_sets_url, notice: 'Annotation set was created successfully.' }
        format.json { render json: { msg: 'Annotation set was created successfully.' } }
      else
        format.html { render :new }
        format.json { render json: { errors: @annotation_set.errors } }
      end
    end
  end

  # PATCH/PUT /annotation_sets/1
  # PATCH/PUT /annotation_sets/1.json
  def update
    respond_to do |format|
      object = prepare_field(annotation_set_params)
      if @annotation_set.update(object)
        format.html { redirect_to annotation_sets_url, notice: 'Annotation set was updated successfully.' }
        format.json { render json: { msg: 'Annotation set was updated successfully.' } }
      else
        format.html { render :edit }
        format.json { render json: { errors: @annotation_set.errors } }
      end
    end
  end

  # DELETE /annotation_sets/1
  # DELETE /annotation_sets/1.json
  def destroy
    @annotation_set.destroy
    flash[:notice] = 'The annotation set was deleted successfully'
    redirect_back(fallback_location: root_path)
  end

  private

  def prepare_field(params)
    dublin_core = []
    if params[:dublincore_value].present?
      params[:dublincore_value].each_with_index do |value, key|
        unless value.blank?
          dublin_core << { key: params[:dublincore_key][key], value: value }
        end
      end
    end
    {
      title: params[:title],
      is_public: params[:is_public],
      dublin_core: dublin_core.to_json,
      updated_by_id: current_user.id
    }
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_annotation_set
    @annotation_set = current_organization.annotation_sets.find_by(id: params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def annotation_set_params
    params.require(:annotation_set).permit(:title, :is_public, dublincore_key: [], dublincore_value: [])
  end
end
