module Bplmodels
  class SimpleObjectBase < Bplmodels::ObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMethods

    has_many :image_files, :class_name => "Bplmodels::ImageFile", :property=> :is_image_of
    belongs_to :institution, :class_name => 'Bplmodels::Institution', :property => :is_member_of


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

    def save
      self.add_relationship(:has_model, "info:fedora/afmodel:Bplmodels_SimpleObjectBase")
      super()
    end

    def to_solr(doc = {} )
      doc = super(doc)
      #doc['has_model_ssim'] = [doc['has_model_ssim'][0], 'info:fedora/afmodel:Bplmodels_SimpleObjectBase']


      doc['label_ssim'] = self.label.to_s
      #1995-12-31T23:59:59.999Z
      doc['dates_created_dtsim'] = []
      doc['dates_created_facet_ssim'] = []
      date_start = -1
      date_end = -1

      if self.descMetadata.date(0).date_other[0] != nil && self.descMetadata.date(0).date_other.length > 0

      else
        if self.descMetadata.date(0).dates_created[0] != nil && self.descMetadata.date(0).dates_created[0].length == 4
          doc['date_created_start_dtsi'] = self.descMetadata.date(0).dates_created[0] + '-01-01T01:00:00.000Z'
          doc['dates_created_dtsim'].append(self.descMetadata.date(0).dates_created[0] + '-01-01T01:00:00.000Z')
          date_start = self.descMetadata.date(0).dates_created[0]
        end
        if self.descMetadata.date(0).dates_created[1] != nil && self.descMetadata.date(0).dates_created[1].length == 4
          doc['date_created_end_dtsi'] = self.descMetadata.date(0).dates_created[1] + '-01-01T01:00:00.000Z'
          doc['dates_created_dtsim'].append(self.descMetadata.date(0).dates_created[1] + '-01-01T01:00:00.000Z')
          date_end = self.descMetadata.date(0).dates_created[1]
        end

      end

      (1850..2000).step(10) do |index|
        if((date_start.to_i >= index && date_start.to_i < index+10) || (date_end.to_i != -1 && date_start.to_i >= index && date_end.to_i < index+10))
          doc['dates_created_facet_ssim'].append(index.to_s + "s")
        end

      end

      doc['abstract_tsi'] = self.descMetadata.abstract

      doc['genre_basic_tsim'] = self.descMetadata.genre_basic
      doc['genre_specific_tsim'] = self.descMetadata.genre_specific

      doc['genre_basic_ssim'] = self.descMetadata.genre_basic
      doc['genre_specific_ssim'] = self.descMetadata.genre_specific

      doc['identifier_local_other_ssim'] = self.descMetadata.local_other

      doc['identifier_ark_ssi'] = ''

      doc['local_accession_id_ssim'] = self.descMetadata.local_accession[0].to_s
      if self.collection
        doc['collection_name_ssim'] = self.collection.label.to_s
      end

      doc['identifier_uri_ssi']  =  self.descMetadata.identifier_uri[1]

      #doc['titleInfo_primary_ssim'] = self.descMetadata.title_info(0).main_title.to_s
      #doc['name_personal_ssim'] = self.descMetadata.name(0).to_s

      doc['name_personal_tsim'] = []
      doc['name_personal_role_tsim'] = []
      doc['name_corporate_tsim'] = []
      doc['name_corporate_role_tsim'] = []

      0.upto self.descMetadata.name.length-1 do |index|
        if self.descMetadata.name(index).type[0] == "personal"
          if self.descMetadata.name(index).date.length > 0
            doc['name_personal_tsim'].append(self.descMetadata.name(index).namePart[0] + ", " + self.descMetadata.name(index).date[0])
          else
            doc['name_personal_tsim'].append(self.descMetadata.name(index).namePart[0])
          end
          doc['name_personal_role_tsim'].append(self.descMetadata.name(index).role.text[0])
        elsif self.descMetadata.name(index).type[0] == "corporate"
          if self.descMetadata.name(index).date.length > 0
            doc['name_corporate_tsim'].append(self.descMetadata.name(index).namePart[0] + ", " + self.descMetadata.name(index).date[0])
          else
            doc['name_corporate_tsim'].append(self.descMetadata.name(index).namePart[0])
          end
          doc['name_corporate_role_tsim'].append(self.descMetadata.name(index).role.text[0])
        end
      end



      if self.descMetadata.name(0).type[0] == "personal"
        doc['name_personal_tsim'] =  [self.descMetadata.name(0).namePart[0]]
        doc['name_personal_role_tsim'] =  [self.descMetadata.name(0).role[0]]
      elsif self.descMetadata.name(0).type[0] == "corporate"
        doc['name_corporate_tsim'] =  [self.descMetadata.name(0).namePart[0]]
        doc['name_corporate_role_tsim'] =  [self.descMetadata.name(0).role[0]]
      end

      doc['type_of_resource_ssim'] = self.descMetadata.type_of_resource

      doc['extent_tsi']  = self.descMetadata.physical_description(0).extent[0]
      doc['digital_origin_ssi']  = self.descMetadata.physical_description(0).digital_origin[0]
      doc['internet_media_type_ssim']  = self.descMetadata.physical_description(0).internet_media_type

      doc['physical_location_ssim']  = self.descMetadata.item_location(0).physical_location
      doc['physical_location_tsim']  = self.descMetadata.item_location(0).physical_location

      doc['sub_location_ssim']  = self.descMetadata.item_location(0).physical_location(0).holding_simple(0).copy_information(0).sub_location
      doc['physical_location_tsim'] = self.descMetadata.item_location(0).physical_location(0).holding_simple(0).copy_information(0).sub_location


      doc['subject_topic_tsim'] = self.descMetadata.subject.topic

      doc['subject_geographic_tsim'] = self.descMetadata.subject.geographic

      doc['subject_geographic_ssim'] = self.descMetadata.subject.geographic


      doc['subject_name_personal_tsim'] = []
      doc['subject_name_corporate_tsim'] = []
      0.upto self.descMetadata.subject.length-1 do |index|
        if self.descMetadata.subject(index).personal_name.length > 0
          if self.descMetadata.subject(index).personal_name.date.length > 0
            doc['subject_name_personal_tsim'].append(self.descMetadata.subject(index).personal_name.name_part[0] + ", " + self.descMetadata.subject(index).personal_name.date[0])
          else
            doc['subject_name_personal_tsim'].append(self.descMetadata.subject(index).personal_name.name_part[0])
          end
        end
        if self.descMetadata.subject(index).corporate_name.length > 0
          if self.descMetadata.subject(index).corporate_name.date.length > 0
            doc['subject_name_corporate_tsim'].append(self.descMetadata.subject(index).corporate_name.name_part[0] + ", " + self.descMetadata.subject(index).corporate_name.date[0])
          else
            doc['subject_name_corporate_tsim'].append(self.descMetadata.subject(index).corporate_name.name_part[0])
          end
        end

      end


      doc['subject_facet_ssim'] = self.descMetadata.subject.topic  +  self.descMetadata.subject.corporate_name.name_part + self.descMetadata.subject.personal_name.name_part

      doc['active_fedora_model_suffix_ssi'] = self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,'')

      doc['use_and_reproduction_ssm'] = self.descMetadata.use_and_reproduction

      doc['note_tsim'] = self.descMetadata.note


      main_title = ''
      if self.descMetadata.title_info(0).nonSort[0] != nil
        doc['title_info_primary_tsi'] =  self.descMetadata.title_info(0).nonSort[0] + ' ' + self.descMetadata.title_info(0).main_title[0]
        main_title = self.descMetadata.title_info(0).nonSort[0] + ' ' + self.descMetadata.title_info(0).main_title[0]
      else
        doc['title_info_primary_tsi'] =  self.descMetadata.title_info(0).main_title[0]
        main_title = self.descMetadata.title_info(0).main_title[0]
      end

      doc['title_info_primary_sort_ssort'] = self.descMetadata.title_info(0).main_title[0]


      #doc['all_text_timv'] = [self.descMetadata.abstract, main_title, self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,''),self.descMetadata.item_location(0).physical_location[0]]

      doc
    end

  end
end
