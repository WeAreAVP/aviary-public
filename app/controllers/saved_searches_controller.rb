# controllers/saved_searches_controllers.rb
#
# SavedSearchesController
# The module is written to store user searches
#
# Author::    Usman Javaid  (mailto:usman@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SavedSearchesController < ApplicationController
  include ApplicationHelper
  before_action :authenticate_user!
  before_action :set_saved_search, only: %i[edit update destroy]

  def index
    return render json: SavedSearchDatatable.new(view_context) if request.xhr?
  end

  def new; end

  def create
    @saved_search = SavedSearch.new(saved_search_params)
    @saved_search.organization_id = current_organization.id if current_organization.present?
    @saved_search.user_id = current_user.id
    if @saved_search.save
      @response = { status: 'success', msg: 'Successfully saved search' }
    else
      @errors = @saved_search.errors.full_messages.join(' and ')
      if @errors.include?('Url has already been saved')
        @saved_search = current_user.saved_searches.where(url: params[:saved_search][:url])[0]
        @update = true
      else
        @update = false
      end
      @response = { status: 'danger', msg: "Failed to save search. #{@errors}" }
    end
  end

  def edit; end

  def update
    @saved_search.update(saved_search_params)
  end

  def destroy
    if @saved_search.present?
      @saved_search.destroy
      @response = { msg: 'Search deleted successfully!', status: 'success' }
    else
      @response = { msg: "Couldn't find saved search with the id '#{params[:id]}'!", status: 'danger' }
    end
  end

  private

  def set_saved_search
    @saved_search = current_user.saved_searches.find(params[:id])
  end

  def saved_search_params
    params.require(:saved_search).permit(:title, :note, :url)
  end
end