module Thesaurus
  # ThesaurusDatatable
  class ThesaurusInformationDatatable < ApplicationDatatable
    delegate :link_to, :edit_thesaurus_manager_path, :thesaurus_manager_path, :strip_tags, :truncate, to: :@view

    def initialize(view, current_organization, field_has_thesaurus)
      @view = view
      @current_organization = current_organization
      @field_has_thesaurus = field_has_thesaurus
    end

    private

    def data
      all_thesaurus, count = thesaurus
      thesaurus_data = all_thesaurus.map do |thesauru|
        [].tap do |column|
          column << thesauru.title
          column << truncate(strip_tags(thesauru.description.to_s).gsub('::', ' '), length: 50)
          column << (thesauru.number_of_terms.present? ? thesauru.number_of_terms : 0)
          column << thesauru.updated_by.first_name + ' ' + thesauru.updated_by.last_name
          column << thesauru.updated_at.to_date
          fields = if @field_has_thesaurus[thesauru.id.to_s].present? && @field_has_thesaurus[thesauru.id.to_s].present?
                     @field_has_thesaurus[thesauru.id.to_s]
                   else
                     []
                   end
          html_link = if fields.present?
                        link_to 'Field Listing', 'javascript:void(0)', class: 'btn-sm btn-default field_listing_popup', data: { toggle: 'modal', list_of_fields: fields.join(','), target: '#field_listing_theasurus_popup',
                                                                                                                                title: thesauru.title, id: thesauru.id }
                      else
                        'none'
                      end
          column << html_link
          advance_action_html = links(thesauru)
          column << advance_action_html
        end
      end
      [thesaurus_data, count]
    end

    def links(path)
      advance_action_html = ''

      advance_action_html += '&nbsp;'
      # Assign Thesaurus to Field button
      advance_action_html += link_to 'Thesaurus Assignment', 'javascript:void(0)', class: 'btn-sm btn-default assign_thesaurus_to_field', data: { toggle: 'modal', target: '#assign_thesaurus_to_fields_popup', title: path.title, id: path.id }
      advance_action_html += '&nbsp;'

      if path.parent_id.blank? || path.parent_id.to_i <= 0
        advance_action_html += '&nbsp;'
        # edit button
        advance_action_html += link_to 'Edit', edit_thesaurus_manager_path(path), class: 'btn-sm btn-success '
      end
      advance_action_html += '&nbsp;'



      # Delete button
      advance_action_html += link_to 'Delete', 'javascript://', class: 'btn-sm btn-danger thesauru_delete', data: { url: thesaurus_manager_path(path), name: path.title }
      advance_action_html += '&nbsp;'
      advance_action_html
    end

    def count; end

    def thesaurus
      fetch_data
    end

    def status(query)
      query ? 'Yes' : 'No'
    end

    def fetch_data
      search_string = []
      columns.each do |term|
        search_string << "#{term} like :search"
      end
      thesaurus, count = Thesaurus::Thesaurus.fetch_list(page, per_page, params[:search][:value], @current_organization.id)
      thesaurus = thesaurus.order(sort_column => sort_direction)

      [thesaurus, count]
    end

    def columns
      %w[title description number_of_terms updated_by_id updated_at]
    end
  end
end
