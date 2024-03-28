# OhmsBreadcrumbPresenter
# Author::  Furqan Wasi(mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class OhmsBreadcrumbPresenter < BasePresenter
  delegate :ohms_records_path, :sync_interviews_manager_path, :ohms_index_path, :add_breadcrumb, to: :h
  include ApplicationHelper
  include DetailPageHelper

  def self.stopwords
    %w[a an and are as at be but by for if in into is it no not of on or such that the their then there these they this
       to was will with]
  end

  def breadcrumb_manager(type, interview, option = '')
    ohms_link = "<a class='inactive-breadcrum'>OHMS</a>".html_safe
    active_link = 'class="active" href="javascript:void(0);" aria-current="page"'
    interview_link = "<a href='#{ohms_records_path}'>OHMS Studio</a>".html_safe
    case type
    when 'edit'
      add_breadcrumb ohms_link
      add_breadcrumb interview_link

      add_edit_breadcrusm(interview, option, active_link)
    when 'show'
      add_breadcrumb ohms_link
      add_breadcrumb interview_link

      add_show_breadcrums(option, active_link)
    end
  end

  def add_edit_breadcrusm(interview, option, active_link)
    case option
    when 'index'
      add_breadcrumb "<a href='#{ohms_index_path(interview.id)}'>Index</a>".html_safe
      add_breadcrumb "<a #{active_link}>Index Editor</a>".html_safe
    when 'sync'
      # interview variable has transcript object in this context
      # so we need to do interview.interview.id to get interview.id
      add_breadcrumb "<a href='#{sync_interviews_manager_path(interview.try(:interview).try(:id) || interview.id)}'>" \
                     'Transcript Sync</a>'.html_safe
      add_breadcrumb "<a #{active_link}>Transcript Editor</a>".html_safe
    else
      add_breadcrumb "<a #{active_link}>Metadata Editor</a>".html_safe
    end
  end

  def add_show_breadcrums(option, active_link)
    case option
    when 'index'
      add_breadcrumb "<a #{active_link}>Index</a>".html_safe
    when 'sync'
      add_breadcrumb "<a #{active_link}>Transcript Sync</a>".html_safe
    end
  end
end
