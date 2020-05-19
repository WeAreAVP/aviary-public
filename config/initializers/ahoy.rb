# Ahoy::Store
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    super(data)
    visitor_information = Ahoy::Visit.where(visit_token: data[:visit_token])
    role_name = Role::all_user_types[4]
    visitor_information.first.update(user_type: role_name)
  end
  
  def track_event(data)
    data[:target_id] = data[:properties]['target_id'] if data[:properties]['target_id'].present?
    data[:ip] = data[:properties]['ip'] if data[:properties]['ip'].present?
    data[:organization_id] = data[:properties]['organization_id'] if data[:properties]['organization_id'].present?
    data[:search_keyword] = data[:properties]['search_keyword'] if data[:properties]['search_keyword'].present?
    data[:user_type] = data[:properties]['user_type'] if data[:properties]['user_type'].present?
    search_keyword = data[:search_keyword].strip unless data[:search_keyword].nil?
    if data[:name] == 'search_page'
      data[:result_count] = data[:properties]['result_count'] if data[:properties]['result_count'].present?
      data[:search_tracking_id] = SearchTracking.create({ result_count: data[:result_count], search_keyword: search_keyword, search_type: data[:name] }).id
    end
    if data[:name] == 'detail_search'
      data[:search_tracking_id] = SearchTracking.create({ result_count: data[:result_count], search_keyword: search_keyword, search_type: data[:name],
                                                          description_count: data[:properties]['description_count'],
                                                          index_count: data[:properties]['index_count'],
                                                          transcript_count: data[:properties]['transcript_count']
                                                        }).id
    end
    super(data)
    visitor_information = Ahoy::Visit.where(visit_token: data[:visit_token])
    visitor_for_update = visitor_information.where(organization_id: nil)
    visitor_for_update.update_all(organization_id: data[:organization_id])
    visitor_information = Ahoy::Visit.where(visit_token: data[:visit_token])
    if visitor_information.present?
      if visitor_information.first.user_id.present?
        role_user = User.find(visitor_information.first.user_id).organization_users.where(organization_id: visitor_information.first.organization_id)
        role_name = if role_user.present? && role_user.first.role.present?
                      role_user.first.role.system_name
                    else
                      Role::all_user_types[3]
                    end
      else
        role_name = Role::all_user_types[4]
      end
      visitor_information.first.update(user_type: role_name) if visitor_information.first.user_type != role_name
    end
  end
end

# set to true for JavaScript tracking
Ahoy.api = true

# better user agent parsing
Ahoy.user_agent_parser = :device_detector

# better bot detection
Ahoy.bot_detection_version = 2
