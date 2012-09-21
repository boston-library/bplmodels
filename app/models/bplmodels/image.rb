module Bplmodels
  class Image < ActiveFedora::Base
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMethods
    include ActiveFedora::Relationships

    belongs_to :collection, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection

    has_metadata :name => "descMetadata", :type => ModsDescMetadata
    has_metadata :name => "admin", :type => AdminDatastream

    #has_file_datastream :name => "productionMaster", :type => FileContentDatastream
    #has_file_datastream :name => "accessMaster", :type => FileContentDatastream

    delegate :title, :to=>'descMetadata', :at => [:mods, :titleInfo, :title], :unique=>true
    delegate :abstract, :to => "descMetadata"
    delegate :description, :to=>'descMetadata', :at => [:abstract], :unique=>true
    delegate :url, :to=>'descMetadata', :at => [:relatedItem, :location, :url], :unique=>true
    delegate :description, :to=>'descMetadata', :at => [:abstract], :unique=>true
    delegate :identifier_accession, :to=>'descMetadata', :at => [:identifier_accession], :unique=>true
    delegate :identifier_barcode, :to=>'descMetadata', :at => [:identifier_barcode], :unique=>true
    delegate :identifier_bpldc, :to=>'descMetadata', :at => [:identifier_bpldc], :unique=>true
    delegate :identifier_other, :to=>'descMetadata', :at => [:identifier_other], :unique=>true

    delegate :state, :to=>'admin', :at => [:item_status, :state], :unique=>true
    delegate :state_comment, :to=>'admin', :at => [:item_status, :state_comment], :unique=>true

    #has_relationship "collections", :is_member_of_collection, :type => Collection

    def apply_default_permissions
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"edit"} )
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"read"} )
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"discover"} )
      self.save
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

  end
end

