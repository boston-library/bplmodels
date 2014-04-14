module Bplmodels
  class SimpleObjectBase < Bplmodels::ObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    include Hydra::AccessControls::Permissions
    include Hydra::ModelMethods

    belongs_to :institution, :class_name => 'Bplmodels::Institution', :property => :is_member_of

    belongs_to :collection, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection

    belongs_to :organization, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection
    has_and_belongs_to_many :members, :class_name=> "Bplmodels::Collection", :property=> :hasSubset

    has_metadata :name => "descMetadata", :type => ModsDescMetadata
    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    has_attributes :abstract, :datastream=>'descMetadata', :at => [:mods, :abstract], :multiple=> false
    has_attributes :title, :datastream=>'descMetadata', :at => [:mods, :title],  :multiple=> true
    has_attributes :supplied_title, :datastream=>'descMetadata', :at => [:mods, :title_info, :supplied],  :multiple=> true
    has_attributes :note_value, :datastream=>'descMetadata', :at => [:mods, :note],  :multiple=> true
    has_attributes :workflow_state, :datastream=>'workflowMetadata', :at => [:item_status, :state],  :multiple=> true
    has_attributes :creator_name, :datastream=>'descMetadata', :at => [:mods, :name, :namePart],  :multiple=> true
    has_attributes :creator_type, :datastream=>'descMetadata', :at => [:mods, :name, :type],  :multiple=> true
    has_attributes :creator_role, :datastream=>'descMetadata', :at => [:mods, :name, :role, :text],  :multiple=> true
    has_attributes :resource_type, :datastream=>'descMetadata', :at => [:mods, :type_of_resource],  :multiple=> true
    has_attributes :manuscript, :datastream=>'descMetadata', :at => [:mods, :type_of_resource, :manuscript],  :multiple=> true
    has_attributes :genre, :datastream=>'descMetadata', :at => [:mods, :genre_basic],  :multiple=> true
    has_attributes :identifier, :datastream=>'descMetadata', :at=>[:mods, :identifier],  :multiple=> true
    has_attributes :identifier_type, :datastream=>'descMetadata', :at=>[:mods, :identifier, :type_at],  :multiple=> true
    has_attributes :publisher_name, :datastream=>'descMetadata', :at=>[:mods, :origin_info, :publisher],  :multiple=> true
    has_attributes :publisher_place, :datastream=>'descMetadata', :at=>[:mods, :origin_info, :place, :place_term],  :multiple=> true
    has_attributes :extent, :datastream=>'descMetadata', :at=>[:mods, :physical_description, :extent],  :multiple=> true
    has_attributes :digital_source, :datastream=>'descMetadata', :at=>[:mods, :physical_description, :digital_origin],  :multiple=> true
    has_attributes :note, :datastream=>'descMetadata', :at=>[:mods, :note],  :multiple=> true
    has_attributes :note_type, :datastream=>'descMetadata', :at=>[:mods, :note, :type_at],  :multiple=> true
    has_attributes :subject_place_value, :datastream=>'descMetadata', :at=>[:mods, :subject, :geographic],  :multiple=> true
    has_attributes :subject_name_value, :datastream=>'descMetadata', :at=>[:mods, :subject, :name, :name_part],  :multiple=> true
    has_attributes :subject_name_type, :datastream=>'descMetadata', :at=>[:mods, :subject, :name, :type],  :multiple=> true
    has_attributes :subject_topic_value, :datastream=>'descMetadata', :at=>[:mods, :subject, :topic],  :multiple=> true
    has_attributes :subject_authority, :datastream=>'descMetadata', :at=>[:mods, :subject, :authority],  :multiple=> true
    has_attributes :language, :datastream=>'descMetadata', :at=>[:mods, :language, :language_term],  :multiple=> true
    has_attributes :language_uri, :datastream=>'descMetadata', :at=>[:mods, :language, :language_term, :lang_val_uri],  :multiple=> true




    #has_file_datastream :name => "productionMaster", :type => FileContentDatastream
    #has_file_datastream :name => "accessMaster", :type => FileContentDatastream

    #delegate :title, :to=>'descMetadata', :at => [:mods, :titleInfo, :title]
    #delegate :abstract, :to => "descMetadata"
    has_attributes :description, :datastream=>'descMetadata', :at => [:abstract],  :multiple=> false
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
