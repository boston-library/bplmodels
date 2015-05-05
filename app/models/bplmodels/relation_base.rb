module Bplmodels
  class RelationBase < ActiveFedora::Base
    include Hydra::AccessControls::Permissions
    include Hydra::ModelMethods

    #include Hydra::ModelMixins::CommonMetadata
    #include Hydra::ModelMethods
    #include Hydra::ModelMixins::RightsMetadata

    include ActiveFedora::Auditable

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    has_metadata :name => "descMetadata", :type => ModsDescMetadata

    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    # collections and institutions can have an associated image file
    has_many :image_files, :class_name => "Bplmodels::ImageFile", :property=> :is_image_of

    has_attributes :abstract, :datastream=>'descMetadata', :at => [:abstract], :multiple=>false



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
      #FIXME
      if self.class.to_s == 'Bplmodels::Institution' ||  self.class.to_s == 'Bplmodels::Collection'
        doc['active_fedora_model_suffix_ssi'] = self.class.to_s.gsub(/\A[\w]*::/,'')
      else
        doc['active_fedora_model_suffix_ssi'] = self.class.superclass.to_s.gsub(/\A[\w]*::/,'')
      end

      # title fields
      title_prefix = self.descMetadata.mods(0).title_info(0).nonSort[0].presence || ''
      main_title = self.descMetadata.mods(0).title_info(0).main_title[0]
      doc['title_info_primary_tsi'] = title_prefix + main_title
      doc['title_info_primary_ssort'] = main_title

      if self.workflowMetadata
        doc['workflow_state_ssi'] = self.workflowMetadata.item_status.state
      end
      puts self.pid
      doc
    end

=begin
    def save
      super()
    end
=end

    def assert_content_model
      super()
      object_superclass = self.class.superclass
      until object_superclass == ActiveFedora::Base || object_superclass == Object do
        add_relationship(:has_model, object_superclass.to_class_uri)
        object_superclass = object_superclass.superclass
      end
    end

    #Rough initial attempt at this implementation
    #use test2.relationships(:has_model)?
    def convert_to(klass)
      #if !self.instance_of?(klass)
      adapted_object = self.adapt_to(klass)

      self.relationships.each_statement do |statement|
        if statement.predicate == "info:fedora/fedora-system:def/model#hasModel"
          self.remove_relationship(:has_model, statement.object)
        end
      end

      adapted_object.assert_content_model
      adapted_object.save
      #end

    end

  end
end