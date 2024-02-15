module IndexesControllerHelper
  def assert_file_index_points(file_index, expected_count)
    expect(file_index.file_index_points.count).to eq(expected_count)
  end

  def assert_file_index_point(
    point, title, start_time, end_time, partial_script, gps_latitude, gps_longitude,
    gps_zoom, gps_description, hyperlink, hyperlink_description, subjects, keywords,
    parent_id, publisher, contributor, segment_date, identifier, rights, synopsis,
    gps_points, hyperlinks
  )
    expect(point.title).to eq(title)
    expect(point.start_time).to eq(start_time)
    expect(point.end_time).to eq(end_time)
    expect(point.partial_script).to eq(partial_script)
    expect(point.gps_latitude).to eq(gps_latitude.to_json)
    expect(point.gps_longitude).to eq(gps_longitude.to_json)
    expect(point.gps_zoom).to eq(gps_zoom.to_json)
    expect(point.gps_description).to eq(gps_description.to_json)
    expect(point.hyperlink).to eq(hyperlink.to_json)
    expect(point.hyperlink_description).to eq(hyperlink_description.to_json)
    expect(point.subjects).to eq(subjects)
    expect(point.keywords).to eq(keywords)
    expect(point.parent_id).to eq(parent_id)
    expect(point.publisher).to eq(publisher)
    expect(point.contributor).to eq(contributor)
    expect(point.segment_date).to eq(segment_date)
    expect(point.identifier).to eq(identifier)
    expect(point.rights).to eq(rights)
    expect(point.synopsis).to eq(synopsis)
    expect(point.gps_points).to eq(gps_points.to_json)
    expect(point.hyperlinks).to eq(hyperlinks.to_json)
  end
end
