# Ahoy::Store
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    super
    AhoyVisitJob.perform_later(data.to_json)
  rescue StandardError
    puts 'Ignore the error as its an invalid data'
  end

  def track_event(data)
    data[:target_id] = data[:properties]['target_id'] if data[:properties]['target_id'].present?
    data[:ip] = data[:properties]['ip'] if data[:properties]['ip'].present?
    data[:organization_id] = data[:properties]['organization_id'] if data[:properties]['organization_id'].present?
    data[:search_keyword] = data[:properties]['search_keyword'] if data[:properties]['search_keyword'].present?
    data[:user_type] = data[:properties]['user_type'] if data[:properties]['user_type'].present?
    search_keyword = data[:search_keyword].strip unless data[:search_keyword].nil?
    data[:parent_id] = begin
                         if data[:name] == 'collection_resource'
                           CollectionResource.where(id: data[:target_id]).first.collection_id
                         elsif data[:name] == 'collection_resource_file' || data[:name] == 'collection_resource_file_play' || data[:name] == 'detail_search'
                           CollectionResourceFile.where(id: data[:target_id]).first.collection_resource.collection_id
                         elsif data[:name] == 'index'
                           FileIndex.where(id: data[:target_id]).first.collection_resource_file.collection_resource.collection.id
                         elsif data[:name] == 'transcript'
                           FileTranscript.where(id: data[:target_id]).first.collection_resource_file.collection_resource.collection.id
                         end
                       rescue StandardError
                         nil
                       end
    if data[:name] == 'search_page'
      data[:result_count] = data[:properties]['result_count'] if data[:properties]['result_count'].present?
      data[:search_tracking_id] = SearchTracking.create({ result_count: data[:result_count], search_keyword: search_keyword, search_type: data[:name] }).id
    end
    if data[:name] == 'detail_search'
      data[:search_tracking_id] = SearchTracking.create({ result_count: data[:result_count], search_keyword: search_keyword, search_type: data[:name],
                                                          description_count: data[:properties]['description_count'],
                                                          index_count: data[:properties]['index_count'],
                                                          transcript_count: data[:properties]['transcript_count'] }).id
    end
    super
    AhoyEventJob.perform_later(data.to_json)
  end
end

# set to true for JavaScript tracking
Ahoy.api = true

# better user agent parsing
Ahoy.user_agent_parser = :device_detector

# better bot detection
Ahoy.bot_detection_version = 2

# Ahoy.cookie_options = { httponly: true, secure: Rails.env.production?, same_site: :lax }

# Debug API requests in Ruby
# Ahoy.quiet = false
