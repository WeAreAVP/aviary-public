# AccessRequestsDatatable
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class Datatables::CollectionsDatatable < Datatables::ApplicationDatatable
  delegate :link_to, :collection_url, :edit_collection_path, :collection_path, :list_resources_collection_path, :list_media_collection_path, :bulk_resource_list_collections_path, :can?, to: :@view

  def initialize(view, current_organization)
    @view = view
    @current_organization = current_organization
  end

  private

  def data
    all_collections, count = collections
    collections_data = all_collections.map do |collection|
      [].tap do |column|
        column << %(
          <label><span class="sr-only">Aviary collection with ID #{collection.id} titled #{collection.title}</span>
            <input type='checkbox' class='resources_selections resources_selections-#{collection.id}'
                data-url='#{bulk_resource_list_collections_path(collection_id: collection.id)}' data-id='#{collection.id}' />
          </label>
        )
        column << collection.title
        column << collection.collection_resources_count
        column << status(collection.is_featured)
        column << status(collection.is_public)
        advance_action_html = links(collection)
        column << advance_action_html
      end
    end
    [collections_data, count]
  end

  def links(path)
    advance_action_html = ''
    advance_action_html += '&nbsp;'
    # view button
    advance_action_html += link_to 'View', collection_url(path, host: Utilities::AviaryDomainHandler.subdomain_handler(path.organization)), class: 'btn-sm btn-default'
    advance_action_html += '&nbsp;'
    # edit button
    advance_action_html += link_to 'Edit', edit_collection_path(path), class: 'btn-sm btn-success'
    advance_action_html += '&nbsp;'
    # Delete button
    advance_action_html += link_to 'Delete', 'javascript://', class: 'btn-sm btn-danger collection_delete', data: { url: collection_path(path), name: path.title } if can? :destroy, path
    advance_action_html += '&nbsp;'
    # Manage Resources button
    advance_action_html += link_to 'Manage Resources', list_resources_collection_path(path), class: 'btn-sm btn-primary'
    advance_action_html += '&nbsp;'
    # Manage Media button
    advance_action_html += link_to 'Manage Media', list_media_collection_path(path), class: 'btn-sm btn-primary'
    advance_action_html + '&nbsp;'
  end

  def count; end

  def collections
    fetch_data
  end

  def status(query)
    query == true ? 'Yes' : 'No'
  end

  def fetch_data
    search_string = []
    columns.each do |term|
      search_string << "#{term} like :search"
    end
    collections, count = Collection.fetch_list(page, per_page, params[:search][:value], @current_organization.id)
    collections = if sort_column == 'is_featured'
                    collections.order(" FIELD(collections.is_featured, true, false) #{sort_direction}")
                  elsif sort_column == 'is_public'
                    collections.order(" FIELD(collections.is_public, true, false) #{sort_direction}")
                  else
                    collections.order(sort_column => sort_direction)
                  end
    [collections, count]
  end

  def columns
    # Patch here as click_through to handle displaying checkboxes on the frontend but starting the sorting from title column instead
    %w[title collection_resources_count is_featured is_public action]
  end
end
