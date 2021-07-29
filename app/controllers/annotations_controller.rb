# controllers/annotations_controller.rb
#
# AnnotationsController
# The class is responsible for managing annotations for the collection resource, transcript and indexes
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class AnnotationsController < ApplicationController
  before_action :set_annotation, only: %i[show update destroy]
  before_action :authenticate_user!, except: :show
  load_and_authorize_resource
  skip_authorize_resource only: :show
  layout false

  # GET /annotation_sets/1
  def show
    authorize! :read, @annotation.annotation_set.file_transcript.collection_resource_file.collection_resource
    render json: @annotation
  end

  # POST /annotation_sets
  # POST /annotation_sets.json
  def create
    @annotation = Annotation.new(annotation_params)
    sequence = Annotation.where(annotation_set_id: @annotation.annotation_set_id).order('sequence').last.try(:sequence)
    sequence = sequence.present? ? sequence + 1 : 1
    @annotation.created_by_id = current_user.id
    @annotation.updated_by_id = current_user.id
    @annotation.sequence = sequence
    respond_to do |format|
      if @annotation.save
        format.html { redirect_to annotation_sets_url, notice: 'Annotation created successfully.' }
        format.json { render json: { msg: 'Annotation created successfully.', id: @annotation.id } }
      else
        format.html { render :new }
        format.json { render json: { errors: @annotation.errors } }
      end
    end
  end

  # PATCH/PUT /annotation_sets/1
  # PATCH/PUT /annotation_sets/1.json
  def update
    respond_to do |format|
      if @annotation.update(annotation_params)
        @annotation.update_attribute('updated_by_id', current_user.id)
        format.html { redirect_to annotation_sets_url, notice: 'Annotation updated successfully.' }
        format.json { render json: { msg: 'Annotation updated successfully.', id: @annotation.id } }
      else
        format.html { render :edit }
        format.json { render json: { errors: @annotation.errors } }
      end
    end
  end

  # DELETE /annotations/1
  # DELETE /annotations/1.json
  def destroy
    @annotation.destroy
    render json: { msg: 'Annotation deleted successfully.' }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_annotation
    @annotation = Annotation.find_by(id: params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def annotation_params
    params.permit(:annotation_set_id, :target_type, :target_content_id, :target_content, :body_type, :body_format, :body_content, :target_info, :target_sub_id)
  end
end
