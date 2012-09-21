module Bplmodels
  class Collection < ActiveFedora::Base
    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMethods
    include ActiveFedora::Relationships

    #has_relationship "similar_audio", :has_part, :type=>AudioRecord
    has_and_belongs_to_many :images, :class_name=> "Bplmodels::Image", :property=> :has_image

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    # Uses the Hydra modsCollection profile for collection list
    has_metadata :name => "members", :type => Hydra::ModsCollectionMembers


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


    #A collection can have another collection as a member, or an image
    def insert_member(fedora_object)
      if (fedora_object.instance_of?(Bplmodels::Image))

        #add to the members ds
        members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>'image')

        #add to the rels-ext ds
        fedora_object.collections << self
        self.images << fedora_object
        #self.add_relationship(:has_image, "info:fedora/#{fedora_object.pid}")

      end

      fedora_object.save!
      self.save!

    end


  end
end
