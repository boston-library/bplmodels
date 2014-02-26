module Bplmodels
  class SimpleObjectBase < Bplmodels::ObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMixins::RightsMetadata
    include Hydra::ModelMethods


    belongs_to :institution, :class_name => 'Bplmodels::Institution', :property => :is_member_of


    belongs_to :collection, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection
    belongs_to :organization, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection
    has_and_belongs_to_many :members, :class_name=> "Bplmodels::Collection", :property=> :hasSubset

    has_metadata :name => "descMetadata", :type => ModsDescMetadata
    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    delegate :abstract, :to=>'descMetadata', :at => [:mods, :abstract], :unique=>true
    delegate :title, :to=>'descMetadata', :at => [:mods, :title]
    delegate :supplied_title, :to=>'descMetadata', :at => [:mods, :title_info, :supplied]
    delegate :note_value, :to=>'descMetadata', :at => [:mods, :note]
    delegate :workflow_state, :to=>'workflowMetadata', :at => [:item_status, :state]  #, :unique=>true
    delegate :creator_name, :to=>'descMetadata', :at => [:mods, :name, :namePart]
    delegate :creator_type, :to=>'descMetadata', :at => [:mods, :name, :type]
    delegate :creator_role, :to=>'descMetadata', :at => [:mods, :name, :role, :text]
    delegate :resource_type, :to=>'descMetadata', :at => [:mods, :type_of_resource]
    delegate :manuscript, :to=>'descMetadata', :at => [:mods, :type_of_resource, :manuscript]
    delegate :genre, :to=>'descMetadata', :at => [:mods, :genre_basic]
    delegate :identifier, :to=>'descMetadata', :at=>[:mods, :identifier]
    delegate :identifier_type, :to=>'descMetadata', :at=>[:mods, :identifier, :type_at]
    delegate :publisher_name, :to=>'descMetadata', :at=>[:mods, :origin_info, :publisher]
    delegate :publisher_place, :to=>'descMetadata', :at=>[:mods, :origin_info, :place, :place_term]
    delegate :extent, :to=>'descMetadata', :at=>[:mods, :physical_description, :extent]
    delegate :digital_source, :to=>'descMetadata', :at=>[:mods, :physical_description, :digital_origin]
    delegate :note, :to=>'descMetadata', :at=>[:mods, :note]
    delegate :note_type, :to=>'descMetadata', :at=>[:mods, :note, :type_at]
    delegate :subject_place_value, :to=>'descMetadata', :at=>[:mods, :subject, :geographic]
    delegate :subject_name_value, :to=>'descMetadata', :at=>[:mods, :subject, :name, :name_part]
    delegate :subject_name_type, :to=>'descMetadata', :at=>[:mods, :subject, :name, :type]
    delegate :subject_topic_value, :to=>'descMetadata', :at=>[:mods, :subject, :topic]
    delegate :subject_authority, :to=>'descMetadata', :at=>[:mods, :subject, :authority]
    delegate :language, :to=>'descMetadata', :at=>[:mods, :language, :language_term]
    delegate :language_uri, :to=>'descMetadata', :at=>[:mods, :language, :language_term, :lang_val_uri]




    #has_file_datastream :name => "productionMaster", :type => FileContentDatastream
    #has_file_datastream :name => "accessMaster", :type => FileContentDatastream

    #delegate :title, :to=>'descMetadata', :at => [:mods, :titleInfo, :title]
    #delegate :abstract, :to => "descMetadata"
    delegate :description, :to=>'descMetadata', :at => [:abstract], :unique=>true
    #delegate :url, :to=>'descMetadata', :at => [:relatedItem, :location, :url], :unique=>true
    #delegate :description, :to=>'descMetadata', :at => [:abstract], :unique=>true
    #delegate :identifier_accession, :to=>'descMetadata', :at => [:identifier_accession], :unique=>true
    #delegate :identifier_barcode, :to=>'descMetadata', :at => [:identifier_barcode], :unique=>true
    #delegate :identifier_bpldc, :to=>'descMetadata', :at => [:identifier_bpldc], :unique=>true
    #delegate :identifier_other, :to=>'descMetadata', :at => [:identifier_other], :unique=>true

    #delegate :state, :to=>'admin', :at => [:item_status, :state], :unique=>true
    #delegate :state_comment, :to=>'admin', :at => [:item_status, :state_comment], :unique=>true

    #has_relationship "collections", :is_member_of_collection, :type => Collection

    def apply_default_permissions
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"edit", "Repository Administrators"=>"read", "Repository Administrators"=>"discover"} )
      self.save
    end

    def add_oai_relationships
      self.add_relationship(:oai_item_id, "oai:digitalcommonwealth.org:" + self.pid, true)
    end

    def save_production_master(filename)
      #self.productionMaster.content = File.open(filename).to_blob
      #self.productionMaster.label = "productionMaster datastream"
      #self.productionMaster.mimetype = "image/tiff"
      #self.save
    end

    ## Produce a unique filename that doesn't already exist.
    def temp_filename(basename, tmpdir='/tmp')
      n = 0
      begin
        tmpname = File.join(tmpdir, sprintf('%s%d.%d', basename, $$, n))
        lock = tmpname + '.lock'
        n += 1
      end while File.exist?(tmpname)
      tmpname
    end

    def save
      super()
    end

    def to_solr(doc = {} )
      doc = super(doc)
      doc

    end

  end
end
