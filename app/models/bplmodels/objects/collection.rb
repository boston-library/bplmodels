module Bplmodels
  class Collection < ActiveFedora::Base
    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMethods
    include ActiveFedora::Relationships

    #has_relationship "similar_audio", :has_part, :type=>AudioRecord

    has_metadata :name => "descMetadata", :type => ModsDescMetadata

    delegate :title, :to=>'descMetadata', :at => [:mods, :titleInfo, :title], :unique=>true
    delegate :abstract, :to => "descMetadata"
    delegate :url, :to=>'descMetadata', :at => [:relatedItem, :location, :url], :unique=>true
    delegate :description, :to=>'descMetadata', :at => [:abstract], :unique=>true
    delegate :location, :to=>'descMetadata', :at => [:relatedItem, :location, :physicalLocation], :unique=>true
    delegate :identifier_accession, :to=>'descMetadata', :at => [:identifier_accession], :unique=>true
    delegate :identifier_barcode, :to=>'descMetadata', :at => [:identifier_barcode], :unique=>true
    delegate :identifier_bpldc, :to=>'descMetadata', :at => [:identifier_bpldc], :unique=>true
    delegate :identifier_other, :to=>'descMetadata', :at => [:identifier_other], :unique=>true

    def apply_default_permissions
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"edit"} )
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"read"} )
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"discover"} )
      self.save
    end
  end
end