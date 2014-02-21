module Bplmodels
  class File  < ActiveFedora::Base
    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMethods
    include Hydra::ModelMixins::RightsMetadata

    include ActiveFedora::Auditable

    belongs_to :object, :class_name => "Bplmodels::ObjectBase", :property => :is_image_of

    belongs_to :exemplary, :class_name => "Bplmodels::ObjectBase", :property => :is_exemplary_image_of

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    has_metadata :name => "ARCHV-EXIF", :type => ActiveFedora::Datastream, :label=>'Archive image EXIF metadata'

    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    def apply_default_permissions
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"edit"} )
      self.save
    end

    def save
      self.add_relationship(:has_model, "info:fedora/afmodel:Bplmodels_File")
      super()
    end

    def to_solr(doc = {} )
      doc = super(doc)
      if self.workflowMetadata.marked_for_deletion.present?
        doc['marked_for_deletion_bsi']  =  self.workflowMetadata.marked_for_deletion.first
        doc['marked_for_deletion_reason_ssi']  =  self.workflowMetadata.marked_for_deletion.reason.first
      end

      doc

    end


  end
end