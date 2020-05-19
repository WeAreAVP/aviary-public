# Model of FileIndexPoint
# models/file_index_point.rb
#
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class FileIndexPoint < ApplicationRecord
  belongs_to :file_index
  before_create :manage_gps_points, :manage_hyperlinks

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
end
