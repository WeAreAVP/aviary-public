##
# RangeLimitExtendedHelper
# Overriding Blacklight helper class
#
# @author Furqan Wasi<furqan@weareavp.com, furqan.wasi66@gmail.com>
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
##
module RangeLimitExtendedHelper
  include RangeLimitHelper
  # Overriding Blackligth helper methods
  def range_display(solr_field, my_params = params, _label = nil)
    return '' unless my_params[:range] && my_params[:range][solr_field]
    hash = my_params[:range][solr_field]
    return BlacklightRangeLimit.labels[:missing] if hash['missing']
    if hash['begin'] || hash['end']
      begin_value = hash['begin'].to_i
      end_value = hash['end'].to_i
      begin_value = hash['begin'] if solr_field.end_with?('_lms')
      return "<span class='single'>#{h(begin_value)}</span>".html_safe if begin_value == end_value || solr_field.end_with?('_lms')
      return "<span class='from'>#{h(begin_value)}</span> to <span class='to'>#{h(end_value)}</span>".html_safe unless solr_field == 'description_duration_ls'
      begin_hours = (begin_value / 60).floor
      begin_minutes = begin_value % 60
      end_hours = (end_value / 60).floor
      end_minutes = end_value % 60
      return "<span class='from'>#{h(begin_hours)}hrs #{h(begin_minutes)}min </span> to <span class='to'>#{h(end_hours)}hrs #{h(end_minutes)}min </span>".html_safe
    end
    hash['missing']
    ''
  end

  # Overriding Blackligth helper methods
  def render_range_input(solr_field, type, input_label = nil, maxlength = 4)
    type = type.to_s
    default = params['range'][solr_field][type] if params['range'] && params['range'][solr_field] && params['range'][solr_field][type]
    html = label_tag("range[#{solr_field}][#{type}]", input_label, class: 'sr-only') if input_label.present?
    html ||= ''.html_safe
    extra_class = ''
    extra_class = ' text-center w-100p ' if solr_field.end_with?('_lms')
    html + text_field_tag("range[#{solr_field}][#{type}]", default, maxlength: maxlength, class: "form-control search_range_picker_date range_#{type} #{extra_class}")
  end
end
