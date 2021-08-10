# Interviews
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
module Interviews
    # Interview Note
    class InterviewNote < ApplicationRecord
        include UserTrackable
        belongs_to :interview
        validates_length_of :note, maximum: 1000, allow_blank: false

    end
end