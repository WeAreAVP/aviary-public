# Model of FileIndexPoint
# models/file_index_point.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class FileIndexPoint < ApplicationRecord
  include ActionView::Helpers
  include ApplicationHelper

  belongs_to :file_index
  before_save :manage_gps_points, :manage_hyperlinks
  validate :validate_time_uniqueness
  validates_presence_of :title
  validate :dates_not_out_of_bound
  attr_accessor :id_alt, :title_alt, :partial_script_alt, :keywords_alt, :subjects_alt, :synopsis_alt, :gps_latitude_alt,
                :gps_description_alt, :zoom_alt, :hyperlink_alt, :hyperlink_description_alt, :gps_points_alt, :hyperlinks_alt

  def dates_not_out_of_bound
    duration = file_index.collection_resource_file&.duration
    return if !duration.present? || duration == 0

    if start_time < 0 || start_time > duration
      errors.add(:start_time, "Select a time between 00:00:00 and #{time_to_duration(duration)}")
    end

    return if end_time.nil? || (end_time.present? && (end_time <= duration && end_time >= start_time))

    errors.add(:end_time, "Select a time between 00:00:00 and #{time_to_duration(duration)}")
  end

  def manage_gps_points
    points = []
    unless gps_latitude.nil? && gps_longitude.nil?
      gps_latitude = JSON.parse(self.gps_latitude)
      gps_longitude = JSON.parse(self.gps_longitude)
      gps_zoom = JSON.parse(self.gps_zoom)
      gps_description = JSON.parse(self.gps_description)
      gps_latitude.each_with_index do |gps, index|
        row = {}
        unless gps.empty? && gps_longitude[index].empty?
          row[:lat] = gps
          row[:long] = gps_longitude[index]
          row[:zoom] = gps_zoom[index]
          row[:description] = gps_description[index]
          points << row
        end
      end
    end
    self.gps_points = points.to_json
  end

  def manage_hyperlinks
    links = []
    unless hyperlink.nil?
      hyperlinks = JSON.parse(hyperlink)
      descriptions = JSON.parse(hyperlink_description)
      hyperlinks.each_with_index do |hyperlink, index|
        row = {}
        if hyperlink.present?
          row[:hyperlink] = hyperlink
          row[:description] = descriptions[index]
          links << row
        end
      end
    end
    self.hyperlinks = links.to_json
  end

  def validate_time_uniqueness
    if id.present?
      if FileIndexPoint.where(file_index_id: file_index_id).where(start_time: start_time).where.not(id: id).first
        errors.add(:start_time, 'Entry already exists for time point.')
        return false
      end
    elsif FileIndexPoint.where(file_index_id: file_index_id).where(start_time: start_time).first
      errors.add(:start_time, 'Entry already exists for time point.')
      return false
    end
    true
  end
end
