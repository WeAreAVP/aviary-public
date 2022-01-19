# SearchTracking
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SearchTracking < ApplicationRecord
  has_one :ahoy_event, class_name: 'Ahoy::Event'
  include ApplicationHelper

  def self.fetch_search_terms(page, per_page, sort_column, sort_direction, organization_id, params, export_type = { type: 'search_page', export: false })
    q = params[:search][:value] if params.key?(:search)
    searching_where = ['search_keyword LIKE (?) ', "%#{q}%"] if q.present?
    search_tracking = SearchTracking.select('count(search_trackings.id) as search_count, search_keyword, MAX(ahoy_events.time) time')
                                    .joins(:ahoy_event)
                                    .where(search_type: export_type[:type])
                                    .where('ahoy_events.organization_id' => organization_id)
    search_tracking = search_tracking.where(searching_where) if q.present?
    search_tracking = search_tracking.where('ahoy_events.time BETWEEN ? AND ?', params['startDate'].to_date.beginning_of_day, params['endDate'].to_date.end_of_day) if params['startDate'].present? && params['endDate'].present?
    search_tracking = search_tracking.where('ahoy_events.user_type' => params['user_type']) if params['user_type'].present? && params['user_type'] != 'all'

    sort_direction = sort_direction.upcase
    unless export_type[:export]
      search_tracking = search_tracking.order(Arel.sql(AnalyticsReportsExtended.order_by_handler(sort_column, sort_direction)))
    end

    search_tracking = search_tracking.group(:search_keyword)
    count = search_tracking.length
    search_tracking = search_tracking.limit(per_page).offset((page - 1) * per_page) unless export_type[:export]
    [search_tracking, count]
  end

  def self.fetch_views(type, start_date, end_date, organization_id, user_type)
    case type
    when 'weekly'
      query = Ahoy::Event.select('count(id) count, target_id, name, year(time) year, week(time) week').group('year(time), week(time) ,name')
    when 'monthly'
      query = Ahoy::Event.select('count(id) count, target_id, name, year(time) year, month(time) month').group('year(time), month(time) ,name')
    when 'yearly'
      query = Ahoy::Event.select('count(id) count, target_id, name, year(time) year').group('year(time) ,name')
    when 'daily'
      query = Ahoy::Event.select('count(id) count, target_id, name, year(time) year, month(time) month, day(time) day').group('year(time), month(time), day(time) ,name')
    end
    begin
      query = query.where(name: %w[transcript index collection_resource collection_resource_file_play])
                   .where('ahoy_events.time BETWEEN ? AND ?', start_date.to_date.beginning_of_day, end_date.to_date.end_of_day)
    rescue StandardError
      query = []
    end
    begin
      query = query.where(organization_id: organization_id) if organization_id.present?
      query = query.where(user_type: user_type) if user_type.present? && user_type != 'all'
    rescue StandardError => e
      puts e.backtrace.join("\n")
    end
    graph_info = { category: [], index: { data: {}, name: 'Index Views' }, transcript: { data: {}, name: 'Transcript Views' },
                   collection_resource: { data: {}, name: 'Resource Views' }, collection_resource_file_play: { data: {}, name: 'Media Views' } }
    query.each do |single_view|
      case type
      when 'weekly'
        catg = single_view.year.to_s + '-' + single_view.week.to_s
      when 'monthly'
        catg = single_view.year.to_s + '-' + single_view.month.to_s
      when 'yearly'
        catg = single_view.year.to_s
      when 'daily'
        catg = single_view.year.to_s + '-' + single_view.month.to_s + '-' + single_view.day.to_s
      end
      graph_info[:index][:data][catg] ||= 0
      graph_info[:transcript][:data][catg] ||= 0
      graph_info[:collection_resource][:data][catg] ||= 0
      graph_info[:collection_resource_file_play][:data][catg] ||= 0
      graph_info[single_view.name.to_sym][:data][catg] = (single_view.count.present? ? single_view.count : 0)
      graph_info[:category] << catg unless graph_info[:category].include?(catg)
    end
    graph_info[:index][:data] = graph_info[:index][:data].map(&:second)
    graph_info[:transcript][:data] = graph_info[:transcript][:data].map(&:second)
    graph_info[:collection_resource][:data] = graph_info[:collection_resource][:data].map(&:second)
    graph_info[:collection_resource_file_play][:data] = graph_info[:collection_resource_file_play][:data].map(&:second)
    graph_info
  end
end
