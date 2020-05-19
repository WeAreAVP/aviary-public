class RefactorFileIndexPoints < ActiveRecord::Migration[5.1]
  def up
    add_column :file_index_points, :gps_points, :text
    add_column :file_index_points, :hyperlinks, :text
    file_points = FileIndexPoint.all
    file_points.each do |point|
      gps_points = update_existing_gps(point)
      hyperlinks = update_existing_hyperlinks(point)
      point.update({gps_points: gps_points.to_json, hyperlinks: hyperlinks.to_json})
    end
  end

  def down

  end

  def update_existing_gps(point)
    return [] if point.gps_latitude.nil? && point.gps_longitude.nil?
    gps_points = []
    begin
      gps_latitude = JSON.parse(point.gps_latitude)
      gps_longitude = JSON.parse(point.gps_longitude)
      gps_zoom = JSON.parse(point.gps_zoom)
      gps_description = JSON.parse(point.gps_description)
      gps_latitude.each_with_index do |gps, index|
        row = {}
        unless gps.empty? && gps_longitude[index].empty?
          row[:lat] = gps
          row[:long] = gps_longitude[index]
          row[:zoom] = gps_zoom[index]
          row[:description] = gps_description[index]
          gps_points << row
        end
      end
    rescue StandardError
      row = {}
      unless point.gps_latitude.empty? && point.gps_longitude.empty?
        row[:lat] = point.gps_latitude
        row[:long] = point.gps_longitude
        row[:zoom] = point.gps_zoom
        row[:description] = point.gps_description
        gps_points << row
      end
    end
    gps_points
  end

  def update_existing_hyperlinks(point)
    return [] if point.hyperlink.nil?
    links = []
    begin
      hyperlinks = JSON.parse(point.hyperlink)
      descriptions = JSON.parse(point.hyperlink_description)
      hyperlinks.each_with_index do |hyperlink, index|
        row = {}
        if hyperlink.present?
          row[:hyperlink] = hyperlink
          row[:description] = descriptions[index]
          links << row
        end
      end
    rescue StandardError
      row = {}
      if point.hyperlink.present?
        row[:hyperlink] = point.hyperlink
        row[:description] = point.hyperlink_description
        links << row
      end
    end
    links
  end
end
