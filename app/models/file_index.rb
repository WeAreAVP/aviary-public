# Model of FileIndex
# models/file_index.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class FileIndex < ApplicationRecord
  include XMLFileHandler
  belongs_to :user
  belongs_to :collection_resource_file
  has_many :file_index_points, dependent: :destroy
  has_attached_file :associated_file, validate_media_type: false, default_url: ''
  validates_presence_of :title, :language, message: 'is required.'
  validates_inclusion_of :is_public, in: [true, false], message: 'is required.'
  validates_attachment_content_type :associated_file, content_type: ['text/xml', 'application/xml', 'text/vtt', 'text/plain'], message: 'Only XML and WebVTT formats allowed.'
  validate :validate_file

  scope :public_index, -> { where(is_public: true).order_index }
  scope :order_index, -> { order('sort_order ASC') }

  after_save :update_solr
  after_destroy :update_solr

  def update_solr
    collection_resource_file.collection_resource.reindex_collection_resource
  end

  def validate_file
    return if associated_file.present? && associated_file.queued_for_write[:original].nil?
    file_content_type = associated_file.queued_for_write[:original].content_type
    if ['application/xml', 'text/xml'].include? file_content_type
      doc = Nokogiri::XML(File.read(associated_file.queued_for_write[:original].path))
      error_messages = xml_validation(doc, 'index')
      error_messages.each do |error|
        errors.add(:associated_file, error.message)
      end
      xml_hash = Hash.from_xml(doc.to_s)
      return errors.add(:associated_file, 'No index data found.') unless xml_hash['ROOT']['record']['index'].present?
      index_points = xml_hash['ROOT']['record']['index']['point']
      index_points = [index_points] unless index_points[0].present?
      index_points.each do |single_point|
        if single_point['title'].nil? || single_point['time'].nil?
          errors.add(:associated_file, 'Title or Time is missing against some of the index points.')
          break
        end
      end
    else
      require 'webvtt'
      begin
        webvtt = WebVTT.read(associated_file.queued_for_write[:original].path)
        webvtt.cues.each do |cue|
          if cue.start.nil?
            errors.add(:associated_file, 'Time is missing against some of the index points.')
            break
          end
        end
      rescue StandardError => ex
        errors.add(:associated_file, ex.message)
      end
    end
  end
end
