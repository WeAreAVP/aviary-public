# controllers/transcript_controllers.rb
#
# TranscriptsController
# The module is written to store the index and transcript for the collection resource file
# Currently supports OHMS XML and WebVtt format
# Nokogiri, webvtt-ruby gem is needed to run this module successfully
# dry-transaction gem is needed for adding transcript steps to this process
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.

require 'zlib'
class TranscriptsController < ApplicationController
  before_action :authenticate_user!, except: :export
  before_action :decompress_request_body, only: [:update]
  before_action :find_transcript, only: [:edit]

  skip_before_action :verify_authenticity_token, only: :update

  def index
    authorize! :manage, current_organization
    session[:file_transcript_bulk_edit] = [] unless request.xhr?
    respond_to do |format|
      format.html
      format.json { render json: TranscriptsDatatable.new(view_context, current_organization, params['called_from'], params[:additionalData]) }
    end
  end

  def bulk_file_transcript_edit
    respond_to do |format|
      format.html
      if params['check_type'] == 'bulk_delete'
        FileTranscript.where(id: session[:file_transcript_bulk_edit]).each(&:destroy)
      elsif params['check_type'] == 'change_status'
        FileTranscript.where(id: session[:file_transcript_bulk_edit]).each do |transcript|
          transcript.update(is_public: params['access_type'].to_i)
        end
      elsif params['check_type'] == 'transcript_caption'
        FileTranscript.where(id: session[:file_transcript_bulk_edit]).each do |transcript|
          transcript.update(is_caption: params['caption'].to_i)
        end
      elsif params['check_type'] == 'transcript_download'
        FileTranscript.where(id: session[:file_transcript_bulk_edit]).each do |transcript|
          transcript.update(is_downloadable: params['is_download'].to_i)
        end
      end
      format.json { render json: { message: t('updated_successfully'), errors: false, status: 'success', action: 'bulk_file_transcript_edit' } }
    end
  end

  def create
    if params[:file_transcript_id]
      file_transcript = FileTranscript.find(params[:file_transcript_id])
      if params[:file_transcript][:associated_file_file_name] && !params[:file_transcript][:assocated_file].present?
        file_transcript.associated_file_file_name = params[:file_transcript][:associated_file_file_name]
      end
      success = file_transcript.update(file_transcript_params)
    else
      file_transcript = FileTranscript.new(file_transcript_params)
      file_transcript.user = current_user
      resource_file = CollectionResourceFile.find(params[:resource_file_id])
      file_transcript.collection_resource_file = resource_file
      file_transcript.sort_order = resource_file.file_transcripts.length + 1
      success = file_transcript.save
    end
    respond_to do |format|
      if success
        file_transcript.file_transcript_points.destroy_all if params[:file_transcript_id] && file_transcript_params[:associated_file].present?
        if file_transcript_params[:associated_file].present?
          remove_title = params[:file_transcript][:remove_title] == '1' ? '1' : ''
          result = Aviary::IndexTranscriptManager::TranscriptManager.new.process(file_transcript, remove_title)
          if result.failure?
            file_transcript.destroy
            format.json { render json: [errors: { associated_file: ['Failed to process the file.'] }] }
          else
            format.json { render json: [errors: []] }
          end
        else
          format.json { render json: [errors: []] }
        end
      else
        format.json { render json: [errors: file_transcript.errors] }
      end
    end
  end

  def sort
    unless params[:sort_list].nil?
      params[:cc] ||= []
      params[:sort_list].each_with_index do |id, index|
        is_caption = params[:cc].include? id
        FileTranscript.where(id: id).update(sort_order: index + 1, is_caption: is_caption)
      end
    end
    respond_to do |format|
      format.json { render json: [errors: []] }
    end
  end

  def destroy
    file_transcript = FileTranscript.find(params[:id])
    file_transcript.destroy
    flash[:notice] = t('transcript_deleted')
    redirect_back(fallback_location: root_path)
  end

  def edit
    resource = @transcript.collection_resource_file.collection_resource
    render json: { success: false } unless authorize_resource_access(resource)
    lock_transcript_for_editing
    stt_type, json = process_transcript_based_on_type
    metadata = load_transcript_metadata
    render json: build_response(resource, json, stt_type, metadata)
  end

  def update
    transcript = FileTranscript.find(params[:id])
    # TODO: Move this to use strong parameters
    decompressed_params = request.env['action_dispatch.request.request_parameters']['file_transcript']
    if decompressed_params['slatejs'].present?
      TranscriptEditJob.perform_later({
                                        transcript: transcript,
                                        params: decompressed_params,
                                        current_user_id: current_user.id
                                      })
      render json: { success: true }
    else
      transcript.update(file_transcript_params)
      render json: { success: false }
    end
  end

  def export
    file_transcript = FileTranscript.find_by_id(params[:id])
    if file_transcript.present? && %w[webvtt txt json].include?(params[:type])
      collection_resource = file_transcript.collection_resource_file.collection_resource
      if file_transcript.is_downloadable.positive? && (file_transcript.is_public || collection_resource.can_view || collection_resource.can_edit || (can? :edit, collection_resource.collection.organization))
        export_text = Aviary::ExportTranscript.new.export(file_transcript, params[:type])
        send_data(export_text, filename: file_transcript.associated_file_file_name.sub(/(webvtt|json|txt|srt)$/, params[:type]))
      else
        flash[:notice] = 'You don\'t have the access to download the transcript'
        redirect_back(fallback_location: root_path)
      end
    else
      flash[:notice] = 'Unable to export the transcript.'
      redirect_back(fallback_location: root_path)
    end
  end

  def refresh_hits_annotation
    annotation_count = {}
    file_transcript = FileTranscript.find_by_id(params[:transcript_id])
    annotation_count = FileTranscriptPresenter.new(file_transcript, view_context).count_annotation_occurrence_present(file_transcript.id, annotation_count)
    respond_to do |format|
      format.json { render json: { annotation_count: annotation_count }, status: :accepted }
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def file_transcript_params
    if params[:is_downloadable].present? && params[:is_downloadable].is_a?(String)
      params[:is_downloadable] = (params[:is_downloadable].downcase == 'yes' ? 1 : 0)
    end
    params.require(:file_transcript).permit(:title, :is_caption, :associated_file, :is_public, :language, :is_edit, :draftjs, :description, :is_downloadable)
  end

  def decompress_request_body
    return unless request.headers['Content-Encoding'] == 'gzip'
    request.body.rewind
    decompressed_body = Zlib::GzipReader.new(StringIO.new(request.body.read)).read
    request.env['action_dispatch.request.request_parameters'] = JSON.parse(decompressed_body)
  end

  def find_transcript
    @transcript = FileTranscript.find(params[:id])
  end

  def lock_transcript_for_editing
    @transcript.update(is_edit: true, locked_by: current_user.id)
  end

  def process_transcript_based_on_type
    if @transcript.saved_slate_js.present?
      ['slatejs', @transcript.slate_js]
    elsif @transcript.timestamps.present?
      process_ibm_transcript
    else
      process_vtt_transcript
    end
  end

  def process_ibm_transcript
    ibm_watson = JSON.parse(@transcript.timestamps.gsub('=>', ':'))
    ibm_watson['results'].first['speaker_labels'] ||= []
    ['ibm', ibm_watson.to_json]
  end

  def process_vtt_transcript
    url = URI.parse(@transcript.associated_file.url)
    response = Net::HTTP.get_response(url)
    ['vtt', response.body]
  rescue StandardError
    content = File.read(@transcript.associated_file.path)
    ['vtt', content]
  end

  def fetch_media_url
    @transcript.collection_resource_file.embed_code
  end

  def authorize_resource_access(resource)
    authorize! :read, resource
  end

  def load_transcript_metadata
    {
      is_caption: @transcript.is_caption,
      is_downloadable: @transcript.is_downloadable,
      description: @transcript.description,
      is_public: @transcript.is_public,
      language: @transcript.language
    }
  end

  def build_response(resource, json, stt_type, metadata)
    {
      env: !Rails.env.test?,
      host: root_url(host: Utilities::AviaryDomainHandler.subdomain_handler(current_organization)),
      media_url: fetch_media_url,
      title: @transcript.title,
      resource_title: resource.title,
      transcript: json,
      sst_type: stt_type,
      metadata: metadata
    }
  end
end
