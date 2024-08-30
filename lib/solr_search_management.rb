# SolrSearchManagement
#
# Aviary is an audiovisual content publishing platform with sophisticated features for search and permissions controls.
# Copyright (C) 2019 Audio Visual Preservation Solutions, Inc.
class SolrSearchManagement
  mattr_accessor :solr_select_url, :solr_connection

  def initialize
    self.solr_select_url = "#{ENV.fetch('SOLR_URL', nil)}/select"
  end

  def connect
    self.solr_connection = RSolr.connect(retry_503: 1, retry_after_limit: 1)
  end

  def select_query(params)
    connect
    solr_connection.post solr_select_url, params.merge({ wt: 'json' })
  end
end
