module Bplmodels
  class OAIObject < Bplmodels::SimpleObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream


    def fedora_name
      'oai_object'
    end

    def to_solr(doc = {} )
      doc = super(doc)
      doc['active_fedora_model_ssi'] = self.class.name
      doc
    end
  end
end