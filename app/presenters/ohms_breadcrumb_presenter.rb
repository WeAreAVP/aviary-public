# OhmsBreadcrumbPresenter
# Author::  Furqan Wasi(mailto:furqan@weareavp.com)
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class OhmsBreadcrumbPresenter < BasePresenter
  delegate :interviews_managers_path, :sync_interviews_manager_path, :interviews_interview_index_path, :add_breadcrumb, to: :h
  include ApplicationHelper
  include DetailPageHelper

  def self.stopwords
    %w(a an and are as at be but by for if in into is it no not of on or such that the their then there these they this to was will with)
  end

  def breadcrumb_manager(type, interview, option = '')
    ohms_link = "<a href='javascript:;'>OHMS</a>".html_safe
    active_link = 'class="active" href="javascript:void(0);"'
    interview_link = "<a href='#{interviews_managers_path}'>OHMS Studio</a>".html_safe
    case type
    when 'edit'
      add_breadcrumb ohms_link
      add_breadcrumb interview_link
      if option == 'index'
        add_breadcrumb "<a href='#{interviews_interview_index_path(interview.id)}'>Index</a>".html_safe
        add_breadcrumb "<a #{active_link}>Index Editor</a>".html_safe
      elsif option == 'sync'
        add_breadcrumb "<a href='#{sync_interviews_manager_path(interview.interview.id)}'>Transcript Sync</a>".html_safe
        add_breadcrumb "<a #{active_link}>Transcript Editor</a>".html_safe
      else
        add_breadcrumb "<a #{active_link}>Metadata Editor</a>".html_safe
      end
    when 'show'
      add_breadcrumb ohms_link
      add_breadcrumb interview_link
      if option == 'index'
        add_breadcrumb "<a #{active_link}>Index</a>".html_safe
      elsif option == 'sync'
        add_breadcrumb "<a #{active_link}>Transcript Sync</a>".html_safe

      end
    end
  end
end
