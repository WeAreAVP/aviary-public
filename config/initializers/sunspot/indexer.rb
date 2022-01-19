require 'sunspot/batcher'
# Sunspot module's over write
module Sunspot
  #
  # This class presents a service for adding, updating, and removing data
  # from the Solr index. An Indexer instance is associated with a particular
  # setup, and thus is capable of indexing instances of a certain class (and its
  # subclasses).
  #
  class Indexer #:nodoc:
    def initialize(connection)
      @connection = connection
    end

    def custom_field_handler(model, documents)
      if model.class == Array && model.first.present? && model.first.class.name == 'CollectionResource' && model.first.custom_description_solr.present?
        model.first.custom_description_solr.each do |key, single|
          single['value'].each do |single_value|
            type_field = Aviary::SolrIndexer.field_type_finder(single['type'])
            if single['type'] == 'date'
              documents.first.fields << RSolr::Field.new({ name: key.to_s + Aviary::SolrIndexer.field_type_finder('simple_string') }, single_value)
              single_value = Aviary::SolrIndexer.date_handler(single_value)
            else
              documents.first.fields << RSolr::Field.new({ name: key.to_s + Aviary::SolrIndexer.field_type_finder('editor') }, single_value)
            end
            documents.first.fields << RSolr::Field.new({ name: key.to_s + type_field }, single_value)
          end
        end
      end
      documents
    end

    #
    # Construct a representation of the model for indexing and send it to the
    # connection for indexing
    #
    # ==== Parameters
    #
    # model<Object>:: the model to index
    #
    def add(model)
      documents = Util.Array(model).map { |m| prepare_full_update(m) }
      documents = custom_field_handler(model, documents)
      add_batch_documents(documents)
    end
  end
end
