module Bplmodels
  class SimpleObjectBase < Bplmodels::ObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    include Hydra::ModelMixins::CommonMetadata
    include Hydra::ModelMixins::RightsMetadata
    include Hydra::ModelMethods

    has_many :exemplary_image, :class_name => "Bplmodels::ImageFile", :property=> :is_exemplary_image_of

    has_many :image_files, :class_name => "Bplmodels::ImageFile", :property=> :is_image_of


    belongs_to :institution, :class_name => 'Bplmodels::Institution', :property => :is_member_of


    belongs_to :collection, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection
    belongs_to :organization, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection
    has_and_belongs_to_many :members, :class_name=> "Bplmodels::Collection", :property=> :hasSubset

    has_metadata :name => "descMetadata", :type => ModsDescMetadata
    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    delegate :abstract, :to=>'descMetadata', :at => [:abstract], :unique=>true
    delegate :title, :to=>'descMetadata', :at => [:title]


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
      #self.add_relationship(:has_model, "info:fedora/afmodel:Bplmodels_SimpleObjectBase")
      super()
    end

    def to_solr(doc = {} )
      doc = super(doc)
      #doc['has_model_ssim'] = [doc['has_model_ssim'][0], 'info:fedora/afmodel:Bplmodels_SimpleObjectBase']


      doc['label_ssim'] = self.label.to_s
      #1995-12-31T23:59:59.999Z
      doc['date_start_dtsi'] = []
      doc['date_start_tsim'] = []
      doc['date_end_dtsi'] = []
      doc['date_end_tsim'] = []
      doc['date_facet_ssim'] = []
      date_start = -1
      date_end = -1

      if self.descMetadata.date(0).date_other[0] != nil && self.descMetadata.date(0).date_other.length > 0
        if self.descMetadata.date(0).date_other[0] == 'undated'
          # do nothing -- don't want to index this
        else
          # TODO insert code for date_other values here
        end
      else
        # TODO refactor this date stuff for other date types
        if self.descMetadata.date(0).dates_created[0] != nil
          date_start = self.descMetadata.date(0).dates_created[0]
          date_start.length > 4 ? date_range_start = date_start[0..3] : date_range_start = date_start
          doc['date_start_tsim'].append(date_start)
          doc['date_start_qualifier_ssm'] = self.descMetadata.date(0).dates_created.qualifier[0]
          if date_start.length == 4
            doc['date_start_dtsi'].append(date_start + '-01-01T00:00:00.000Z')
          elsif date_start.length == 7
            doc['date_start_dtsi'].append(date_start + '-01T01:00:00.000Z')
          elsif date_start.length > 11
            doc['date_start_dtsi'].append(date_start)
          else
            doc['date_start_dtsi'].append(date_start + 'T00:00:00.000Z')
          end
        end
        if self.descMetadata.date(0).dates_created[1] != nil
          date_end = self.descMetadata.date(0).dates_created[1]
          date_end.length > 4 ? date_range_end = date_end[0..3] : date_range_end = date_end
          doc['date_end_tsim'].append(date_end)
          doc['date_end_qualifier_ssm'] = self.descMetadata.date(0).dates_created.qualifier[1]
          if date_start.length == 4
            doc['date_end_dtsi'].append(date_end + '-01-01T00:00:00.000Z')
          elsif date_start.length == 7
            doc['date_end_dtsi'].append(date_end + '-01T00:00:00.000Z')
          elsif date_start.length > 11
            doc['date_end_dtsi'].append(date_end)
          else
            doc['date_end_dtsi'].append(date_end + 'T00:00:00.000Z')
          end
        end
      end

      (1800..2000).step(10) do |index|
        if ((date_range_start.to_i >= index && date_range_start.to_i < index+10) || (date_range_end.to_i != -1 && index > date_range_start.to_i && date_range_end.to_i >= index))
          doc['date_facet_ssim'].append(index.to_s + "s")
        end
      end

      doc['abstract_tsim'] = self.descMetadata.abstract

      doc['genre_basic_tsim'] = self.descMetadata.genre_basic
      doc['genre_specific_tsim'] = self.descMetadata.genre_specific

      doc['genre_basic_ssim'] = self.descMetadata.genre_basic
      doc['genre_specific_ssim'] = self.descMetadata.genre_specific

      doc['identifier_local_other_tsim'] = self.descMetadata.local_other

      doc['identifier_ark_ssi'] = ''

      doc['local_accession_id_tsim'] = self.descMetadata.local_accession[0].to_s
      if self.collection
        doc['collection_name_ssim'] = self.collection.label.to_s
        doc['collection_name_tsim'] = self.collection.label.to_s
        doc['collection_pid_ssm'] = self.collection.pid

        if self.collection
          if self.collection.institutions
            doc['institution_name_ssim'] = self.collection.institutions.label.to_s
            doc['institution_name_tsim'] = self.collection.institutions.label.to_s
            doc['institution_pid_ssi'] = self.collection.institutions.pid
          end
        end

      end


      #self.descMetadata.identifier_uri.each do |identifier|
      #if idenfifier.include?("ark")
        #doc['identifier_uri_ss']  =  self.descMetadata.identifier_uri
      #end
    #end
      if  self.descMetadata.identifier_uri.length > 1
        doc['identifier_uri_ss']  =  self.descMetadata.identifier_uri[1]
      else
        doc['identifier_uri_ss']  =  self.descMetadata.identifier_uri[0]
      end


      doc['publisher_tsim'] = self.descMetadata.origin_info.publisher

      doc['lang_term_ssim'] = self.descMetadata.language.language_term
      #doc['lang_val_uri_ssim'] = self.descMetadata.language.language_term.lang_val_uri

      if self.descMetadata.related_item.length > 0
        (0..self.descMetadata.related_item.length-1).each do |index|
          related_item_type = self.descMetadata.related_item.type[index]
          if related_item_type == 'isReferencedBy'
            doc['related_item_' + related_item_type.downcase + '_ssm'] ||= []
            doc['related_item_' + related_item_type.downcase + '_ssm'].append(self.descMetadata.related_item(index).href[0])
          else
            doc['related_item_' + related_item_type + '_tsim'] ||= []
            doc['related_item_' + related_item_type + '_ssim'] ||= []
            doc['related_item_' + related_item_type + '_tsim'].append(self.descMetadata.related_item.title_info.title[index])
            doc['related_item_' + related_item_type + '_ssim'].append(self.descMetadata.related_item.title_info.title[index])
          end
        end
      end


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
          doc['name_personal_role_tsim'].append(self.descMetadata.name(index).role.text[0].strip)
        elsif self.descMetadata.name(index).type[0] == "corporate"
          if self.descMetadata.name(index).date.length > 0
            doc['name_corporate_tsim'].append(self.descMetadata.name(index).namePart[0] + ", " + self.descMetadata.name(index).date[0])
          else
            doc['name_corporate_tsim'].append(self.descMetadata.name(index).namePart[0])
          end
          doc['name_corporate_role_tsim'].append(self.descMetadata.name(index).role.text[0].strip)
        end
      end



      if self.descMetadata.name(0).type[0] == "personal"
        doc['name_personal_tsim'] =  [self.descMetadata.name(0).namePart[0]]
        doc['name_personal_role_tsim'] =  [self.descMetadata.name(0).role[0].strip]
      elsif self.descMetadata.name(0).type[0] == "corporate"
        doc['name_corporate_tsim'] =  [self.descMetadata.name(0).namePart[0]]
        doc['name_corporate_role_tsim'] =  [self.descMetadata.name(0).role[0].strip]
      end

      doc['type_of_resource_ssim'] = self.descMetadata.type_of_resource

      doc['extent_tsi']  = self.descMetadata.physical_description(0).extent[0]
      doc['digital_origin_ssi']  = self.descMetadata.physical_description(0).digital_origin[0]
      doc['internet_media_type_ssim']  = self.descMetadata.physical_description(0).internet_media_type

      doc['physical_location_ssim']  = self.descMetadata.item_location(0).physical_location
      doc['physical_location_tsim']  = self.descMetadata.item_location(0).physical_location

      doc['sub_location_tsim']  = self.descMetadata.item_location(0).holding_simple(0).copy_information(0).sub_location

      doc['subject_topic_tsim'] = self.descMetadata.subject.topic

      # subject - geographic
      subject_geo = self.descMetadata.subject.geographic
      doc['subject_geographic_tsim'] = subject_geo

      # hierarchical geo
      country = self.descMetadata.subject.hierarchical_geographic.country
      state = self.descMetadata.subject.hierarchical_geographic.state
      county = self.descMetadata.subject.hierarchical_geographic.county
      city = self.descMetadata.subject.hierarchical_geographic.city
      city_section = self.descMetadata.subject.hierarchical_geographic.city_section

      doc['subject_geo_country_tsim'] = country
      doc['subject_geo_state_tsim'] = state
      doc['subject_geo_county_tsim'] = county
      doc['subject_geo_city_tsim'] = city
      doc['subject_geo_citysection_tsim'] = city_section

      # coordinates
      doc['subject_coordinates_geospatial'] = self.descMetadata.subject.cartographics.coordinates

      # add values to subject-geo facet field
      doc['subject_geographic_ssim'] = subject_geo + county + city + city_section

      doc['subject_name_personal_tsim'] = []
      doc['subject_name_corporate_tsim'] = []
      doc['subject_facet_ssim'] = []
      0.upto self.descMetadata.subject.length-1 do |index|
        if self.descMetadata.subject(index).personal_name.length > 0
          if self.descMetadata.subject(index).personal_name.date.length > 0
            #doc['subject_name_personal_tsim'].append(self.descMetadata.subject(index).personal_name.name_part[0] + ", " + self.descMetadata.subject(index).personal_name.date[0])
            subject_name_personal = self.descMetadata.subject(index).personal_name.name_part[0] + ", " + self.descMetadata.subject(index).personal_name.date[0]
          else
            #doc['subject_name_personal_tsim'].append(self.descMetadata.subject(index).personal_name.name_part[0])
            subject_name_personal = self.descMetadata.subject(index).personal_name.name_part[0]
          end
          doc['subject_name_personal_tsim'].append(subject_name_personal)
          doc['subject_facet_ssim'].append(subject_name_personal)
        end
        if self.descMetadata.subject(index).corporate_name.length > 0
          if self.descMetadata.subject(index).corporate_name.date.length > 0
            #doc['subject_name_corporate_tsim'].append(self.descMetadata.subject(index).corporate_name.name_part[0] + ", " + self.descMetadata.subject(index).corporate_name.date[0])
            subject_name_corporate = self.descMetadata.subject(index).corporate_name.name_part[0] + ", " + self.descMetadata.subject(index).corporate_name.date[0]
          else
            #doc['subject_name_corporate_tsim'].append(self.descMetadata.subject(index).corporate_name.name_part[0])
            subject_name_corporate = self.descMetadata.subject(index).corporate_name.name_part[0]
          end
          doc['subject_name_corporate_tsim'].append(subject_name_corporate)
          doc['subject_facet_ssim'].append(subject_name_corporate)
        end

      end

      #doc['subject_facet_ssim'] = self.descMetadata.subject.topic  +  self.descMetadata.subject.corporate_name.name_part + self.descMetadata.subject.personal_name.name_part

      doc['subject_facet_ssim'].concat(self.descMetadata.subject.topic)

      doc['active_fedora_model_suffix_ssi'] = self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,'')

      doc['use_and_reproduction_ssm'] = self.descMetadata.use_and_reproduction

      doc['note_tsim'] = self.descMetadata.note


      main_title = ''
      if self.descMetadata.title_info(0).nonSort[0] != nil
        doc['title_info_primary_tsi'] =  self.descMetadata.title_info(0).nonSort[0] + ' ' + self.descMetadata.title_info(0).main_title[0]
        doc['title_info_primary_ssort'] = self.descMetadata.title_info(0).main_title[0]
        main_title = self.descMetadata.title_info(0).nonSort[0] + ' ' + self.descMetadata.title_info(0).main_title[0]
      else
        doc['title_info_primary_tsi'] =  self.descMetadata.title_info(0).main_title[0]
        doc['title_info_primary_ssort'] = self.descMetadata.title_info(0).main_title[0]
        main_title = self.descMetadata.title_info(0).main_title[0]
      end

      if self.collection
        if self.collection.institutions
           doc['institution_pid_si'] = self.collection.institutions.pid
        end
      end

      if self.workflowMetadata
        doc['workflow_state_ssi'] = self.workflowMetadata.item_status.state
      end

      if self.exemplary_image.first != nil
        doc['exemplary_image_ss'] = self.exemplary_image.first.pid
      end




      #doc['all_text_timv'] = [self.descMetadata.abstract, main_title, self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,''),self.descMetadata.item_location(0).physical_location[0]]

      doc
    end

  end
end
