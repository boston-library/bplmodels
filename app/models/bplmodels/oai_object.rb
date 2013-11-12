module Bplmodels
  class OAIObject < Bplmodels::SimpleObjectBase

    has_metadata :name => "oaiMetadata", :type => OAIMetadata

    has_many :exemplary_image, :class_name => "Bplmodels::OAIObject", :property=> :is_exemplary_image_of


    has_file_datastream 'thumbnail300', :versionable=>false, :label=>'thumbnail300 datastream'

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