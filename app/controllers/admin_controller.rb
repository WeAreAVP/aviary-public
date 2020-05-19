# AdminController
#
# This controller is responsible for managing common admin methods
# Author::    Nouman Tayyab  (mailto:nouman@weareavp.com)
class AdminController < ApplicationController
  before_action :authenticate_admin!
end
