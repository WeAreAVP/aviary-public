# Model of FileTranscript
# models/file_transcript.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class FileTranscript < ApplicationRecord
  include XMLFileHandler
  belongs_to :collection_resource_file
  has_many :file_transcript_points, dependent: :destroy
  belongs_to :user
  validates_presence_of :title, :language, message: 'is required.'
  validates_inclusion_of :is_public, in: [true, false], message: 'is required.'
  validate :validate_file
  has_attached_file :associated_file, validate_media_type: false, default_url: ''
  validates_attachment_content_type :associated_file, content_type: ['text/xml', 'application/xml', 'text/vtt', 'text/plain'], message: 'Only XML and WebVTT formats allowed.'
  attr_accessor :remove_title
  scope :order_transcript, -> { order('sort_order ASC') }
  scope :public_transcript, -> { where(is_public: true).order_transcript }
  scope :cc, -> { where(is_caption: true) }
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
      error_messages = xml_validation(doc, 'transcript')
      if error_messages.any?
        errors.add(:associated_file, 'Invalid File, please select a valid OHMS XML file.')
      end
      xml_hash = Hash.from_xml(doc.to_s)
      transcript = xml_hash['ROOT']['record']['transcript']
      if transcript.nil?
        errors.add(:associated_file, 'Transcript is empty.')
      end
    elsif file_content_type == 'text/vtt' || ['.vtt', '.webvtt'].include?(File.extname(associated_file.queued_for_write[:original].original_filename).downcase)
      require 'webvtt'
      begin
        WebVTT.read(associated_file.queued_for_write[:original].path)
      rescue StandardError => ex
        errors.add(:associated_file, ex.message)
      end
    end
  end
end
