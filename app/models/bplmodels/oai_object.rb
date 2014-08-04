module Bplmodels
  class OAIObject < Bplmodels::SimpleObjectBase

    has_metadata :name => "oaiMetadata", :type => OAIMetadata

    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

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

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    def self.mint(args)
      args[:namespace_id] = ARK_CONFIG_GLOBAL['namespace_oai_pid']
      #TODO: Duplication check here to prevent over-writes?

      return_object = super(args)

      if !return_object.is_a?(String)
        return_object.workflowMetadata.insert_oai_defaults
      end

      return return_object
    end
  end
end