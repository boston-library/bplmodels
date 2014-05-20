module Bplmodels
  class Newspaper < Bplmodels::ComplexObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    def to_solr(doc = {} )
      doc = super(doc)
      doc['active_fedora_model_ssi'] = self.class.name
      doc
    end

    def fedora_name
      'newspaper'
    end
  end
end