module Bplmodels
  class RelationBase < ActiveFedora::Base
    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMethods
    include Hydra::ModelMixins::RightsMetadata

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    has_metadata :name => "descMetadata", :type => ModsDescMetadata

    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    # collections and institutions can have an associated image file
    has_many :image_files, :class_name => "Bplmodels::ImageFile", :property=> :is_image_of

    #delegate :title, :to=>'descMetadata', :at => [:mods, :titleInfo, :title], :unique=>true
    #delegate :abstract, :to => "descMetadata"
    #delegate :url, :to=>'descMetadata', :at => [:relatedItem, :location, :url], :unique=>true
    #delegate :description, :to=>'descMetadata', :at => [:abstract], :unique=>true
    #delegate :location, :to=>'descMetadata', :at => [:relatedItem, :location, :physicalLocation], :unique=>true
    #delegate :identifier_accession, :to=>'descMetadata', :at => [:identifier_accession], :unique=>true
    #delegate :identifier_barcode, :to=>'descMetadata', :at => [:identifier_barcode], :unique=>true
    #delegate :identifier_bpldc, :to=>'descMetadata', :at => [:identifier_bpldc], :unique=>true
    #delegate :identifier_other, :to=>'descMetadata', :at => [:identifier_other], :unique=>true


    def apply_default_permissions
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"edit"} )
      self.save
    end

    def to_solr(doc = {} )
      doc = super(doc)
      doc['label_ssim'] = self.label
      doc['active_fedora_model_suffix_ssi'] = self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,'')
      if self.workflowMetadata
        doc['workflow_state_ssi'] = self.workflowMetadata.item_status.state
      end
      puts self.pid
      doc
    end

    def save
      self.add_relationship(:has_model, "info:fedora/afmodel:Bplmodels_RelationBase")
      super()
    end

  end


end