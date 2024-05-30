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
    session['index_update_backward_duration'] = params['index_update_backward_duration'].presence || session['index_update_backward_duration']
    session['index_update_forward_duration'] = params['index_update_forward_duration'].presence || session['index_update_forward_duration']
  end
end
