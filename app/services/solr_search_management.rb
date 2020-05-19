# SolrSearchManagement
class SolrSearchManagement
  mattr_accessor :solr_select_url, :solr_connection

  def initialize
    self.solr_select_url = "#{ENV['SOLR_URL']}/select"
  end

  def connect
    self.solr_connection = RSolr.connect(retry_503: 1, retry_after_limit: 1)
  end

  def select_query(params)
    connect
    solr_connection.get solr_select_url, params: params
  end
end
