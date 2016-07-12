module Bplmodels
  class OAICollection < Bplmodels::Collection
    def fedora_name
      'oai_collection'
    end
    # To change this template use File | Settings | File Templates.

    def to_solr(doc = {} )
      super(doc)

      exemplary_check = Bplmodels::OAIObject.find_with_conditions({"is_exemplary_image_of_ssim"=>"info:fedora/#{self.pid}"}, rows: '1', fl: 'id' )
      if exemplary_check.present?
        doc['exemplary_image_ssi'] = exemplary_check.first["id"]
      end

      doc

    end

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    def self.mint(args)
       args[:namespace_id] = ARK_CONFIG_GLOBAL['namespace_oai_pid']

      super(args)
    end
  end
end