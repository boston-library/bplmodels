module Bplmodels
  class OAICollection < Bplmodels::Collection
    def fedora_name
      'oai_collection'
    end
    # To change this template use File | Settings | File Templates.

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