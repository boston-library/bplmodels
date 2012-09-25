module Bplmodels
  class ImageFile  < ActiveFedora::Base
    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMethods
    include Hydra::ModelMixins::RightsMetadata
    include ActiveFedora::Relationships

    belongs_to :collection, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection

    has_and_belongs_to_many :image, :class_name => "Bplmodels::Image", :property => :is_image_of

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    has_metadata :name => "ARCHV-EXIF", :type => ActiveFedora::Datastream, :label=>'Archive image EXIF metadata'

    def apply_default_permissions
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"edit"} )
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"read"} )
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"discover"} )
      self.save
    end

  end
end