module Bplmodels
  class SimpleObjectBase < Bplmodels::ObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMethods

    belongs_to :collection, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection
    belongs_to :organization, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection
    has_and_belongs_to_many :members, :class_name=> "Bplmodels::Collection", :property=> :hasSubset

    has_metadata :name => "descMetadata", :type => ModsDescMetadata
    has_metadata :name => "admin", :type => AdminDatastream

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata


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

    def to_solr(doc = {} )
      doc = super(doc)
      doc['label_ssim'] = self.label.to_s



      doc['local_other_id_ssim'] = self.descMetadata.local_other[0].to_s
      doc['local_accession_id_ssim'] = self.descMetadata.local_accession[0].to_s
      if self.collection
        doc['collection_name_ssim'] = self.collection.label.to_s
      end

      #doc['titleInfo_primary_ssim'] = self.descMetadata.title_info(0).main_title.to_s
      #doc['name_personal_ssim'] = self.descMetadata.name(0).to_s
      if self.descMetadata.name(0).type[0] == "personal"
        doc['name_personal_ssim'] =  self.descMetadata.name(0).namePart[0]
        doc['name_personal_role_ssim'] =  self.descMetadata.name(0).role[0]
      elsif self.descMetadata.name(0).type[0] == "corporate"
        doc['name_corporate_ssim'] =  self.descMetadata.name(0).namePart[0]
        doc['name_corporate_role_ssim'] =  self.descMetadata.name(0).role[0]
      end

      doc['typeOfResource_ssim'] = self.descMetadata.type_of_resource[0]

      doc['extent_ssim']  = self.descMetadata.physical_description(0).extent[0]
      doc['digitalOrigin_ssim']  = self.descMetadata.physical_description(0).digital_origin[0]
      doc['internetMediaType_ssim']  = self.descMetadata.physical_description(0).internet_media_type[0]

      doc['physicalLocation_ssim']  = self.descMetadata.item_location(0).physical_location[0]
      doc['subLocation_ssim']  = self.descMetadata.item_location(0).physical_location(0).holding_simple(0).copy_information(0).sub_location[0]

      doc['identifier_uri_ssim']  =  self.descMetadata.identifier_uri[1]
      doc['identifier_local-other_ssim']  = self.descMetadata.local_other[0]


      doc['subject_topic_ssim'] = self.descMetadata.subject.topic

      doc['subject_geographic_ssim'] = self.descMetadata.subject.geographic

      doc['subject_name_personal_ssim'] =   self.descMetadata.subject.personal_name.name_part

      doc['subject_name_corporate_ssim'] =   self.descMetadata.subject.corporate_name.name_part

      doc['active_fedora_model_suffix_ssi'] = self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,'')


      doc
    end

  end
end