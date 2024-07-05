# helpers/indexes_helper.rb
#
# IndexesHelper
# Helper methods common between OHMS and Aviary indexes
#
# Author::    Usman Javaid  (mailto:usmanjzcn@gmail.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module IndexesHelper
  def retrieve_skip_durations
    [session['index_update_forward_duration'] || 10, session['index_update_backward_duration'] || 10]
  end

  def update_skip_duration
    session['index_update_backward_duration'] = params['index_update_backward_duration'].presence ||
                                                session['index_update_backward_duration']
    session['index_update_forward_duration'] = params['index_update_forward_duration'].presence ||
                                               session['index_update_forward_duration']
  end

  def skip_duration_options
    [{ duration: 1, label: '1s' }, { duration: 10, label: '10s' }, { duration: 15, label: '15s' },
     { duration: 20, label: '20s' }, { duration: 30, label: '30s' }, { duration: 45, label: '45s' },
     { duration: 50, label: '50s' }, { duration: 60, label: '60s' }, { duration: 300, label: '5m' }]
  end

  def skip_duration_options_html(target)
    skip_duration_options.map do |option|
      "<li><a href='javascript:void(0)' class='dropdown-item update_duration_option' data-target='#{target}' " \
        "data-value='#{option[:duration]}'> #{option[:label]}</a></li>"
    end.join
  end
end
