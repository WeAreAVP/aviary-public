# AdminController
#
# This controller is responsible for managing common admin methods
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class AdminController < ApplicationController
  before_action :authenticate_admin!
end
