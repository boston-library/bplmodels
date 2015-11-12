module Bplmodels
  class ObjectBase < ActiveFedora::Base
    # To change this template use File | Settings | File Templates.
    include ActiveFedora::Auditable
    include Hydra::AccessControls::Permissions
    include Hydra::ModelMethods

    has_many :exemplary_image, :class_name => "Bplmodels::File", :property=> :is_exemplary_image_of

    has_many :image_files, :class_name => "Bplmodels::ImageFile", :property=> :is_image_of

    has_many :audio_files, :class_name => "Bplmodels::AudioFile", :property=> :is_audio_of

    has_many :document_files, :class_name => "Bplmodels::DocumentFile", :property=> :is_document_of

    has_many :ereader_files, :class_name => "Bplmodels::EreaderFile", :property=> :is_ereader_of

    has_many :files, :class_name => "Bplmodels::File", :property=> :is_file_of



    belongs_to :institution, :class_name => 'Bplmodels::Institution', :property => :is_member_of

    has_and_belongs_to_many :collection, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection

    #has_and_belongs_to_many :organization, :class_name => 'Bplmodels::Collection', :property => :is_member_of_collection

    belongs_to :admin_set, :class_name => 'Bplmodels::Collection', :property => :administrative_set

    has_and_belongs_to_many :members, :class_name=> "Bplmodels::Collection", :property=> :hasSubset

    has_metadata :name => "descMetadata", :type => ModsDescMetadata
    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    has_file_datastream 'marc', versionable: false, label: 'MARC metadata'
    has_file_datastream 'iaMeta', versionable: false, label: 'Internet Archive metadata'
    has_file_datastream 'scanData', versionable: false, label: 'Internet Archive scanData metadata'
    has_file_datastream 'plainText', versionable: false, label: 'Plain Text representation of this object'
    has_file_datastream 'djvuXML', versionable: false, label: 'XML version of DJVU output'
    has_file_datastream 'abbyy', versionable: false, label: 'Abbyy OCR of this object'

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
    has_attributes :description, :datastream=>'descMetadata', :at => [:abstract],  :multiple=> false



    def apply_default_permissions
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"edit", "Repository Administrators"=>"read", "Repository Administrators"=>"discover"} )
      self.save
    end

    def add_oai_relationships
      self.add_relationship(:oai_item_id, "oai:digitalcommonwealth.org:" + self.pid, true)
    end

    #alias :limited_delete :delete

=begin
    def save
      super()
    end
=end

    def delete(delete_files=true)
      if delete_files
        Bplmodels::File.find_in_batches('is_file_of_ssim'=>"info:fedora/#{self.pid}") do |group|
          group.each { |solr_file|
            file = Bplmodels::File.find(solr_file['id']).adapt_to_cmodel
            file.delete
          }
        end
      end
      super()
    end

    #Rough initial attempt at this implementation
    #use test2.relationships(:has_model)?
    def convert_to(klass)
      #if !self.instance_of?(klass)
      adapted_object = self.adapt_to(klass)

      adapted_object.relationships.each_statement do |statement|
        if statement.predicate == "info:fedora/fedora-system:def/model#hasModel"
          adapted_object.remove_relationship(:has_model, statement.object)
          #puts statement.object
        end
      end

      adapted_object.assert_content_model
      adapted_object.save
      adapted_object
      #end

    end


    def assert_content_model
      super()
      object_superclass = self.class.superclass
      until object_superclass == ActiveFedora::Base || object_superclass == Object do
        add_relationship(:has_model, object_superclass.to_class_uri)
        object_superclass = object_superclass.superclass
      end
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
      doc['date_type_ssm'] = []
      doc['date_start_qualifier_ssm'] = []
      dates_static = []
      dates_start = []
      dates_end = []

      # dateOther
      if self.descMetadata.date(0).date_other[0] != nil && self.descMetadata.date(0).date_other.length > 0
        if self.descMetadata.date(0).date_other[0] == 'undated'
          # do nothing -- don't want to index this
        else
          # TODO insert code for date_other values here
        end
      end

      # dateCreated, dateIssued, copyrightDate
      if self.descMetadata.date(0).dates_created[0] || self.descMetadata.date(0).dates_issued[0] || self.descMetadata.date(0).dates_copyright[0]

        #dateCreated
        if self.descMetadata.date(0).dates_created[0]
          self.descMetadata.date(0).dates_created.each_with_index do |date,index|
          #FIXME: Has to add "date.present" and the when '' case for oai-test:h415pc718
           if date.present?
              case self.descMetadata.date(0).dates_created(index).point[0]
                when nil, ''
                  dates_static << date
                  doc['date_type_ssm'] << 'dateCreated'
                  doc['date_start_qualifier_ssm'].append(self.descMetadata.date(0).dates_created(index).qualifier[0].presence || 'nil')
                when 'start'
                  dates_start << date
                  doc['date_type_ssm'] << 'dateCreated'
                  doc['date_start_qualifier_ssm'].append(self.descMetadata.date(0).dates_created(index).qualifier[0].presence || 'nil')
                when 'end'
                  dates_end << date
              end
            end
          end
        end
        # dateIssued
        if self.descMetadata.date(0).dates_issued[0]
          self.descMetadata.date(0).dates_issued.each_with_index do |date,index|
            case self.descMetadata.date(0).dates_issued(index).point[0]
              when nil
                dates_static << date
                doc['date_type_ssm'] << 'dateIssued'
                doc['date_start_qualifier_ssm'].append(self.descMetadata.date(0).dates_issued(index).qualifier[0].presence || 'nil')
              when 'start'
                dates_start << date
                doc['date_type_ssm'] << 'dateIssued'
                doc['date_start_qualifier_ssm'].append(self.descMetadata.date(0).dates_issued(index).qualifier[0].presence || 'nil')
              when 'end'
                dates_end << date
            end
          end
        end
        # dateCopyright
        if self.descMetadata.date(0).dates_copyright[0]
          self.descMetadata.date(0).dates_copyright.each_with_index do |date,index|
            case self.descMetadata.date(0).dates_copyright(index).point[0]
              when nil
                dates_static << date
                doc['date_type_ssm'] << 'copyrightDate'
                doc['date_start_qualifier_ssm'].append(self.descMetadata.date(0).dates_copyright(index).qualifier[0].presence || 'nil')
              when 'start'
                dates_start << date
                doc['date_type_ssm'] << 'copyrightDate'
                doc['date_start_qualifier_ssm'].append(self.descMetadata.date(0).dates_copyright(index).qualifier[0].presence || 'nil')
              when 'end'
                dates_end << date
            end
          end
        end

        # push the date values as-is into text fields
        dates_static.each do |static_date|
          doc['date_start_tsim'] << static_date
          doc['date_end_tsim'] << 'nil' # hacky, but can't assign null in Solr
        end
        dates_start.each do |start_date|
          doc['date_start_tsim'] << start_date
        end
        dates_end.each do |end_date|
          doc['date_end_tsim'] << end_date
        end

        # set the date ranges for date-time fields and decade faceting
        earliest_date = (dates_static + dates_start).sort[0]
        date_facet_start = earliest_date[0..3].to_i

        if earliest_date.length == 4
          doc['date_start_dtsi'].append(earliest_date + '-01-01T00:00:00.000Z')
        elsif earliest_date.length == 7
          doc['date_start_dtsi'].append(earliest_date + '-01T01:00:00.000Z')
        elsif earliest_date.length > 11
          doc['date_start_dtsi'].append(earliest_date)
        else
          doc['date_start_dtsi'].append(earliest_date + 'T00:00:00.000Z')
        end

        if dates_end[0]
          latest_date = dates_end.reverse[0]
          date_facet_end = latest_date[0..3].to_i
          if latest_date.length == 4
            doc['date_end_dtsi'].append(latest_date + '-12-31T23:59:59.999Z')
          elsif latest_date.length == 7
            # TODO: DD value should be dependent on MM value
            # e.g., '31' for January, but '28' for February, etc.
            doc['date_end_dtsi'].append(latest_date + '-28T23:59:59.999Z')
          elsif latest_date.length > 11
            doc['date_end_dtsi'].append(latest_date)
          else
            doc['date_end_dtsi'].append(latest_date + 'T23:59:59.999Z')
          end
        else
          date_facet_end = 0
        end

        # decade faceting
        (1500..2020).step(10) do |index|
          if ((date_facet_start >= index && date_facet_start < index+10) || (date_facet_end != -1 && index > date_facet_start && date_facet_end >= index))
            doc['date_facet_ssim'].append(index.to_s + 's')
          end
        end

        doc['date_facet_yearly_ssim'] = []
        # yearly faceting
        (1500..2020).step(1) do |index|
          if ((date_facet_start >= index && date_facet_start < index+1) || (date_facet_end != -1 && index > date_facet_start && date_facet_end >= index))
            doc['date_facet_yearly_ssim'].append(index.to_s + 's')
          end
        end

      end

      doc['abstract_tsim'] = self.descMetadata.abstract
      doc['table_of_contents_tsi'] = self.descMetadata.table_of_contents[0]

      doc['genre_basic_tsim'] = self.descMetadata.genre_basic
      doc['genre_specific_tsim'] = self.descMetadata.genre_specific

      doc['genre_basic_ssim'] = self.descMetadata.genre_basic
      doc['genre_specific_ssim'] = self.descMetadata.genre_specific

      # will need to make this more generic when we have more id fields with @invalid
      if self.descMetadata.local_other
        doc['identifier_local_other_tsim'] = []
        doc['identifier_local_other_invalid_tsim'] = []
        self.descMetadata.identifier.each_with_index do |id_val, index|
          if self.descMetadata.identifier(index).type_at[0] == 'local-other'
            if self.descMetadata.identifier(index).invalid[0]
              doc['identifier_local_other_invalid_tsim'].append(id_val)
            else
              doc['identifier_local_other_tsim'].append(id_val)
            end
          end
        end
      end


      doc['identifier_local_call_tsim'] = self.descMetadata.local_call
      doc['identifier_local_barcode_tsim'] = self.descMetadata.local_barcode
      doc['identifier_isbn_tsim'] = self.descMetadata.isbn
      doc['identifier_lccn_tsim'] = self.descMetadata.lccn
      doc['identifier_ia_id_ssi'] = self.descMetadata.ia_id

      doc['identifier_ark_ssi'] = ''

      doc['local_accession_id_tsim'] = self.descMetadata.local_accession[0].to_s

      #Assign collection, admin, and institution labels
      doc['collection_name_ssim'] = []
      doc['collection_name_tsim'] = []
      doc['collection_pid_ssm'] = []

      object_institution_pid = nil
      object_collections = self.relationships(:is_member_of_collection)
      object_collections.each do |collection_ident|
        solr_response_collection = ActiveFedora::Base.find_with_conditions("id"=>collection_ident.gsub('info:fedora/','')).first
        doc['collection_name_ssim'] << solr_response_collection["label_ssim"].first.to_s
        doc['collection_name_tsim'] << solr_response_collection["label_ssim"].first.to_s
        doc['collection_pid_ssm'] << solr_response_collection["id"].to_s

        if object_institution_pid.blank?
          object_institution_pid = solr_response_collection['institution_pid_ssi']
          solr_response_institution = ActiveFedora::Base.find_with_conditions("id"=>object_institution_pid).first
          doc['institution_name_ssim'] = solr_response_institution["label_ssim"].first.to_s
          doc['institution_name_tsim'] = solr_response_institution["label_ssim"].first.to_s
          doc['institution_pid_ssi'] = solr_response_institution["id"].to_s
          doc['institution_pid_si'] = solr_response_institution["id"].to_s
        end
      end

      object_admin_set = self.relationships(:administrative_set).first
      if object_admin_set.present?
        solr_response_admin = ActiveFedora::Base.find_with_conditions("id"=>object_admin_set.gsub('info:fedora/','')).first
        doc['admin_set_name_ssim'] = solr_response_admin["label_ssim"].first.to_s
        doc['admin_set_name_tsim'] = solr_response_admin["label_ssim"].first.to_s
        doc['admin_set_pid_ssm'] = solr_response_admin["id"].to_s
      else
        raise "Potential problem setting administrative set?"
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

      doc['pubplace_tsim'] = self.descMetadata.origin_info.place.place_term

      doc['edition_tsim'] = self.descMetadata.origin_info.edition

      doc['issuance_tsim'] = self.descMetadata.origin_info.issuance

      doc['classification_tsim'] = self.descMetadata.classification

      doc['lang_term_ssim'] = self.descMetadata.language.language_term
      #doc['lang_val_uri_ssim'] = self.descMetadata.language.language_term.lang_val_uri

      # relatedItem, except subseries, subsubseries, etc.
      if self.descMetadata.mods(0).related_item.length > 0
        (0..self.descMetadata.mods(0).related_item.length-1).each do |index|
          related_item_type = self.descMetadata.mods(0).related_item(index).type[0]
          if related_item_type == 'isReferencedBy'
            doc['related_item_' + related_item_type.downcase + '_ssm'] ||= []
            doc['related_item_' + related_item_type.downcase + '_ssm'].append(self.descMetadata.mods(0).related_item(index).href[0])
          else
            doc['related_item_' + related_item_type + '_tsim'] ||= []
            doc['related_item_' + related_item_type + '_ssim'] ||= []
            related_title_prefix = self.descMetadata.mods(0).related_item(index).title_info.nonSort[0] ? self.descMetadata.mods(0).related_item(index).title_info.nonSort[0] + ' ' : ''
            doc['related_item_' + related_item_type + '_tsim'].append(related_title_prefix + self.descMetadata.mods(0).related_item(index).title_info.title[0])
            doc['related_item_' + related_item_type + '_ssim'].append(related_title_prefix + self.descMetadata.mods(0).related_item(index).title_info.title[0])
          end
        end
      end

      # subseries
      if self.descMetadata.related_item.subseries
        doc['related_item_subseries_tsim'] ||= []
        doc['related_item_subseries_ssim'] ||= []
        (0..self.descMetadata.mods(0).related_item.subseries.length-1).each do |index|
          subseries_prefix = self.descMetadata.mods(0).related_item.subseries(index).title_info.nonSort[0] ? self.descMetadata.mods(0).related_item.subseries(index).title_info.nonSort[0] + ' ' : ''
          subseries_value = subseries_prefix + self.descMetadata.mods(0).related_item.subseries(index).title_info.title[0]
          doc['related_item_subseries_tsim'].append(subseries_value)
          doc['related_item_subseries_ssim'].append(subseries_value)
        end
      end

      # subsubseries
      if self.descMetadata.related_item.subseries.subsubseries
        doc['related_item_subsubseries_tsim'] ||= []
        doc['related_item_subsubseries_ssim'] ||= []
        (0..self.descMetadata.mods(0).related_item.subseries.subsubseries.length-1).each do |index|
          subsubseries_prefix = self.descMetadata.mods(0).related_item.subseries.subsubseries(index).title_info.nonSort[0] ? self.descMetadata.mods(0).related_item.subseries.subsubseries(index).title_info.nonSort[0] + ' ' : ''
          subsubseries_value = subsubseries_prefix + self.descMetadata.mods(0).related_item.subseries.subsubseries(index).title_info.title[0]
          doc['related_item_subsubseries_tsim'].append(subsubseries_value)
          doc['related_item_subsubseries_ssim'].append(subsubseries_value)
        end
      end

      #doc['titleInfo_primary_ssim'] = self.descMetadata.title_info(0).main_title.to_s
      #doc['name_personal_ssim'] = self.descMetadata.name(0).to_s

      doc['name_personal_tsim'] = []
      doc['name_personal_role_tsim'] = []
      doc['name_corporate_tsim'] = []
      doc['name_corporate_role_tsim'] = []

      doc['name_generic_tsim'] = []
      doc['name_generic_role_tsim'] = []

      0.upto self.descMetadata.mods(0).name.length-1 do |index|
        if self.descMetadata.mods(0).name(index).type[0] == "personal"
          if self.descMetadata.mods(0).name(index).date.length > 0
            doc['name_personal_tsim'].append(self.descMetadata.mods(0).name(index).namePart[0] + ", " + self.descMetadata.mods(0).name(index).date[0])
          else
            doc['name_personal_tsim'].append(self.descMetadata.mods(0).name(index).namePart[0])
          end
          if self.descMetadata.mods(0).name(index).role.length > 1
            doc['name_personal_role_tsim'].append(self.descMetadata.mods(0).name(0).role.join('||').gsub(/[\n]\s*/,''))
          else
            doc['name_personal_role_tsim'].append(self.descMetadata.mods(0).name(index).role.text[0])
          end

        elsif self.descMetadata.mods(0).name(index).type[0] == "corporate"
          corporate_name = self.descMetadata.mods(0).name(index).namePart.join(". ").gsub(/\.\./,'.')
          # TODO -- do we need the conditional below?
          # don't think corp names have dates
          if self.descMetadata.mods(0).name(index).date.length > 0
            doc['name_corporate_tsim'].append(corporate_name + ", " + self.descMetadata.mods(0).name(index).date[0])
          else
            doc['name_corporate_tsim'].append(corporate_name)
          end
          if self.descMetadata.mods(0).name(index).role.length > 1
            doc['name_corporate_role_tsim'].append(self.descMetadata.mods(0).name(0).role.join('||').gsub(/[\n]\s*/,''))
          else
            doc['name_corporate_role_tsim'].append(self.descMetadata.mods(0).name(index).role.text[0])
          end

        else
          if self.descMetadata.mods(0).name(index).date.length > 0
            doc['name_generic_tsim'].append(self.descMetadata.mods(0).name(index).namePart[0] + ", " + self.descMetadata.mods(0).name(index).date[0])
          else
            doc['name_generic_tsim'].append(self.descMetadata.mods(0).name(index).namePart[0])
          end
          if self.descMetadata.mods(0).name(index).role.length > 1
            doc['name_generic_role_tsim'].append(self.descMetadata.mods(0).name(0).role.join('||').gsub(/[\n]\s*/,''))
          else
            doc['name_generic_role_tsim'].append(self.descMetadata.mods(0).name(index).role.text[0])
          end
        end

      end

      doc['name_facet_ssim'] = doc['name_personal_tsim'] + doc['name_corporate_tsim'] + doc['name_generic_tsim']


      doc['type_of_resource_ssim'] = self.descMetadata.type_of_resource

      doc['extent_tsi']  = self.descMetadata.physical_description(0).extent[0]
      doc['digital_origin_ssi']  = self.descMetadata.physical_description(0).digital_origin[0]
      doc['internet_media_type_ssim']  = self.descMetadata.physical_description(0).internet_media_type

      doc['physical_location_ssim']  = self.descMetadata.item_location(0).physical_location
      doc['physical_location_tsim']  = self.descMetadata.item_location(0).physical_location

      doc['sub_location_tsim']  = self.descMetadata.item_location(0).holding_simple(0).copy_information(0).sub_location

      doc['shelf_locator_tsim']  = self.descMetadata.item_location(0).holding_simple(0).copy_information(0).shelf_locator

      doc['subject_topic_tsim'] = self.descMetadata.subject.topic

      # subject - geographic
      subject_geo = self.descMetadata.subject.geographic

      # subject - hierarchicalGeographic
      country = self.descMetadata.subject.hierarchical_geographic.country
      province = self.descMetadata.subject.hierarchical_geographic.province
      region = self.descMetadata.subject.hierarchical_geographic.region
      state = self.descMetadata.subject.hierarchical_geographic.state
      territory = self.descMetadata.subject.hierarchical_geographic.territory
      county = self.descMetadata.subject.hierarchical_geographic.county
      city = self.descMetadata.subject.hierarchical_geographic.city
      city_section = self.descMetadata.subject.hierarchical_geographic.city_section
      island = self.descMetadata.subject.hierarchical_geographic.island
      area = self.descMetadata.subject.hierarchical_geographic.area

      doc['subject_geo_country_ssim'] = country
      doc['subject_geo_province_ssim'] = province
      doc['subject_geo_region_ssim'] = region
      doc['subject_geo_state_ssim'] = state
      doc['subject_geo_territory_ssim'] = territory
      doc['subject_geo_county_ssim'] = county
      doc['subject_geo_city_ssim'] = city
      doc['subject_geo_citysection_ssim'] = city_section
      doc['subject_geo_island_ssim'] = island
      doc['subject_geo_area_ssim'] = area

      geo_subjects = (country + province + region + state + territory + area + island + city + city_section + subject_geo).uniq # all except 'county'

      # add all subject-geo values to subject-geo text field for searching (remove dupes)
      doc['subject_geographic_tsim'] = geo_subjects + county.uniq

      # add " (county)" to county values for better faceting
      county_facet = []
      if county.length > 0
        county.each do |county_value|
          county_facet << county_value + ' (county)'
        end
      end

      # add all subject-geo values to subject-geo facet field (remove dupes)
      doc['subject_geographic_ssim'] = geo_subjects + county_facet.uniq

      # scale
      doc['subject_scale_tsim'] = self.descMetadata.subject.cartographics.scale

      # coordinates / bbox
      if self.descMetadata.subject.cartographics.coordinates.length > 0
        doc['subject_coordinates_geospatial'] = self.descMetadata.subject.cartographics.coordinates # includes both bbox and point data
        self.descMetadata.subject.cartographics.coordinates.each do |coordinates|
          if coordinates.scan(/[\s]/).length == 3
            doc['subject_bbox_geospatial'] ||= []
            doc['subject_bbox_geospatial'] << coordinates
          else
            doc['subject_point_geospatial'] ||= []
            doc['subject_point_geospatial'] << coordinates
          end
        end
      end

      # geographic data as GeoJSON (2 fields)
      # subject_geojson_facet_ssim = for map-based faceting + display
      # subject_hiergeo_geojson_ssm = for display of hiergeo metadata
      doc['subject_geojson_facet_ssim'] = []
      doc['subject_hiergeo_geojson_ssm'] = []
      doc['subject_geo_nonhier_ssim'] = [] # other non-hierarchical geo subjects
      0.upto self.descMetadata.subject.length-1 do |subject_index|

        this_subject = self.descMetadata.mods(0).subject(subject_index)

        # TGN-id-derived hierarchical geo subjects. assumes only longlat points, no bboxes
        if this_subject.hierarchical_geographic.any?
          geojson_hash_base = {type: 'Feature', geometry: {type: 'Point'}}

          if this_subject.cartographics.coordinates.any? # get the coordinates
            coords = this_subject.cartographics.coordinates[0]
            if coords.match(/^[-]?[\d]*[\.]?[\d]*,[-]?[\d]*[\.]?[\d]*$/)
              geojson_hash_base[:geometry][:coordinates] = coords.split(',').reverse.map { |v| v.to_f }
            end
          end

          facet_geojson_hash = geojson_hash_base.dup
          hiergeo_geojson_hash = geojson_hash_base.dup

          # get the hierGeo elements, except 'continent'
          hiergeo_hash = {}
          ModsDescMetadata.terminology.retrieve_node(:subject,:hierarchical_geographic).children.each do |hgterm|
            hiergeo_hash[hgterm[0]] = '' unless hgterm[0].to_s == 'continent'
          end
          hiergeo_hash.each_key do |k|
            hiergeo_hash[k] = this_subject.hierarchical_geographic.send(k)[0].presence
          end
          hiergeo_hash.reject! {|k,v| !v } # remove any nil values

          if this_subject.geographic[0]
            other_geo_value = this_subject.geographic[0]
            other_geo_value << " (#{this_subject.geographic.display_label[0]})" if this_subject.geographic.display_label[0]
            hiergeo_hash[:other] = other_geo_value
          end

          unless hiergeo_hash.empty?
            hiergeo_geojson_hash[:properties] = hiergeo_hash
            facet_geojson_hash[:properties] = {placename: DatastreamInputFuncs.render_display_placename(hiergeo_hash)}
            doc['subject_hiergeo_geojson_ssm'].append(hiergeo_geojson_hash.to_json)
          end

          if geojson_hash_base[:geometry][:coordinates].is_a?(Array)
            doc['subject_geojson_facet_ssim'].append(facet_geojson_hash.to_json)
          end

        end

        # coordinates or bboxes w/o hierGeo elements, but maybe non-hierGeo geographic strings
        if this_subject.cartographics.coordinates.any? && this_subject.hierarchical_geographic.blank?
          geojson_hash = {type: 'Feature', geometry: {type: '', coordinates: []}}
          coords = this_subject.cartographics.coordinates[0]
          if coords.scan(/[\s]/).length == 3 #bbox TODO: better checking for bbox syntax
            unless coords == '-180.0 -90.0 180.0 90.0' # don't want 'whole world' bboxes
              coords_array = coords.split(' ').map { |v| v.to_f }
              if coords_array[0] > coords_array[2] # bbox that crosses dateline
                if coords_array[0] > 0
                  degrees_to_add = 180-coords_array[0]
                  coords_array[0] = -(180 + degrees_to_add)
                elsif coords_array[0] < 0 && coords_array[2] < 0
                  degrees_to_add = 180+coords_array[2]
                  coords_array[2] = 180 + degrees_to_add
                else
                  Rails.logger.error("This bbox format was not parsed correctly: '#{coords}'")
                end
              end
              geojson_hash[:bbox] = coords_array
              geojson_hash[:geometry][:type] = 'Polygon'
              geojson_hash[:geometry][:coordinates] = [[[coords_array[0],coords_array[1]],
                                                        [coords_array[2],coords_array[1]],
                                                        [coords_array[2],coords_array[3]],
                                                        [coords_array[0],coords_array[3]],
                                                        [coords_array[0],coords_array[1]]]]
            end
          elsif coords.match(/^[-]?[\d]+[\.]?[\d]*,[\s]?[-]?[\d]+[\.]?[\d]*$/)
            geojson_hash[:geometry][:type] = 'Point'
            geojson_hash[:geometry][:coordinates] = coords.split(',').reverse.map { |v| v.to_f }
          end

          if this_subject.geographic[0]
            doc['subject_geo_nonhier_ssim'] << this_subject.geographic[0]
            geojson_hash[:properties] = {placename: this_subject.geographic[0]}
          end

          unless geojson_hash[:geometry][:coordinates].blank?
            doc['subject_geojson_facet_ssim'].append(geojson_hash.to_json)
          end
        end

        # non-hierarchical geo subjects w/o coordinates
        if this_subject.cartographics.coordinates.empty? && this_subject.hierarchical_geographic.blank? && this_subject.geographic[0]
          doc['subject_geo_nonhier_ssim'] << this_subject.geographic[0]
        end

      end

=begin
      new_logger = Logger.new('log/geo_log')
      new_logger.level = Logger::ERROR

      #Blacklight-maps esque placename_coords
      0.upto self.descMetadata.subject.length-1 do |subject_index|
       if self.descMetadata.mods(0).subject(subject_index).cartographics.present? && self.descMetadata.mods(0).subject(subject_index).cartographics.scale.blank?
         place_name = "Results"

         if self.descMetadata.mods(0).subject(subject_index).authority == ['tgn'] && self.descMetadata.mods(0).subject(subject_index).hierarchical_geographic[0].blank?
           new_logger.error "Weird Geography for: " + self.pid
         end

         if self.descMetadata.mods(0).subject(subject_index).authority == ['tgn'] && self.descMetadata.mods(0).subject(subject_index).hierarchical_geographic[0].present?
           place_locations = []
           self.descMetadata.mods(0).subject(subject_index).hierarchical_geographic[0].split("\n").each do |split_geo|
             split_geo = split_geo.strip
             place_locations << split_geo if split_geo.present? && !split_geo.include?('North and Central America') && !split_geo.include?('United States')
           end
           place_name = place_locations.reverse.join(', ')
         elsif self.descMetadata.mods(0).subject(subject_index).geographic.present?
           place_name = self.descMetadata.mods(0).subject(subject_index).geographic.first
         end

         doc['subject_blacklight_maps_ssim'] = "#{place_name}-|-#{self.descMetadata.mods(0).subject(subject_index).cartographics.coordinates[0].split(',').first}-|-#{self.descMetadata.mods(0).subject(subject_index).cartographics.coordinates[0].split(',').last}"
       end
      end
=end
      #Blacklight-maps coords only
=begin
      best_coords_found = false
      0.upto self.descMetadata.subject.length-1 do |subject_index|
        if self.descMetadata.mods(0).subject(subject_index).cartographics.present?
          if self.descMetadata.mods(0).subject(subject_index).authority.present? && self.descMetadata.mods(0).subject(subject_index).authority != ['tgn']
            best_coords_found = true
            doc['subject_blacklight_maps_coords_ssim'] = self.descMetadata.mods(0).subject(subject_index).cartographics.coordinates[0]
          end
        end
      end
      0.upto self.descMetadata.subject.length-1 do |subject_index|
        if self.descMetadata.mods(0).subject(subject_index).cartographics.present? && !best_coords_found
            doc['subject_blacklight_maps_coords_ssim'] = self.descMetadata.mods(0).subject(subject_index).cartographics.coordinates[0]
        end
      end
=end

      # name subjects
      doc['subject_name_personal_tsim'] = []
      doc['subject_name_corporate_tsim'] = []
      doc['subject_name_conference_tsim'] = []
      doc['subject_facet_ssim'] = []
      0.upto self.descMetadata.subject.length-1 do |index|
        if self.descMetadata.subject(index).personal_name.length > 0
          if self.descMetadata.subject(index).personal_name.date.length > 0
            subject_name_personal = self.descMetadata.subject(index).personal_name.name_part[0] + ", " + self.descMetadata.subject(index).personal_name.date[0]
          else
            subject_name_personal = self.descMetadata.subject(index).personal_name.name_part[0]
          end
          doc['subject_name_personal_tsim'].append(subject_name_personal)
          doc['subject_facet_ssim'].append(subject_name_personal)
        end
        if self.descMetadata.subject(index).corporate_name.length > 0
          subject_name_corporate = self.descMetadata.subject(index).corporate_name.name_part.join('. ').gsub(/\.\./,'.')
          # TODO -- do we need the conditional below?
          # don't think corp names have dates
          if self.descMetadata.subject(index).corporate_name.date.length > 0
            subject_name_corporate = subject_name_corporate + ", " + self.descMetadata.subject(index).corporate_name.date[0]
          end
          doc['subject_name_corporate_tsim'].append(subject_name_corporate)
          doc['subject_facet_ssim'].append(subject_name_corporate)
        end
        if self.descMetadata.subject(index).conference_name.length > 0
          subject_name_conference = self.descMetadata.subject(index).conference_name.name_part[0]
          doc['subject_name_conference_tsim'].append(subject_name_conference)
          doc['subject_facet_ssim'].append(subject_name_conference)
        end

      end

      #doc['subject_facet_ssim'] = self.descMetadata.subject.topic  +  self.descMetadata.subject.corporate_name.name_part + self.descMetadata.subject.personal_name.name_part

      doc['subject_facet_ssim'].concat(self.descMetadata.subject.topic)

      # temporal subjects
      if self.descMetadata.subject.temporal.length > 0
        doc['subject_temporal_start_tsim'] = []
        doc['subject_temporal_start_dtsim'] = []
        doc['subject_temporal_facet_ssim'] = []
        subject_date_range_start = []
        subject_date_range_end = []
        self.descMetadata.subject.temporal.each_with_index do |value,index|
          if self.descMetadata.subject.temporal.point[index] != 'end'
            subject_temporal_start = value
            doc['subject_temporal_start_tsim'].append(subject_temporal_start)
            subject_date_range_start.append(subject_temporal_start)
            # subject_temporal_start.length > 4 ? subject_date_range_start.append(subject_temporal_start[0..3]) : subject_date_range_start.append(subject_temporal_start)
            if subject_temporal_start.length == 4
              doc['subject_temporal_start_dtsim'].append(subject_temporal_start + '-01-01T00:00:00.000Z')
            elsif subject_temporal_start.length == 7
              doc['subject_temporal_start_dtsim'].append(subject_temporal_start + '-01T01:00:00.000Z')
            else
              doc['subject_temporal_start_dtsim'].append(subject_temporal_start + 'T00:00:00.000Z')
            end
          else
            doc['subject_temporal_end_tsim'] = []
            doc['subject_temporal_end_dtsim'] = []
            subject_temporal_end = value
            doc['subject_temporal_end_tsim'].append(subject_temporal_end)
            subject_date_range_end.append(subject_temporal_end)
            # subject_temporal_end.length > 4 ? subject_date_range_end.append(subject_temporal_end[0..3]) : subject_date_range_end.append(subject_temporal_end)
            if subject_temporal_end.length == 4
              doc['subject_temporal_end_dtsim'].append(subject_temporal_end + '-01-01T00:00:00.000Z')
            elsif subject_temporal_end.length == 7
              doc['subject_temporal_end_dtsim'].append(subject_temporal_end + '-01T01:00:00.000Z')
            else
              doc['subject_temporal_end_dtsim'].append(subject_temporal_end + 'T00:00:00.000Z')
            end
          end
        end

        if subject_date_range_start.length > 0
          subject_date_range_start.each_with_index do |date_start,index|
            if subject_date_range_end.present?
              doc['subject_temporal_facet_ssim'].append(date_start[0..3] + '-' + subject_date_range_end[index][0..3])
            else
              doc['subject_temporal_facet_ssim'].append(date_start)
            end
          end
        end

        doc['subject_facet_ssim'].concat(doc['subject_temporal_facet_ssim'])

      end

      # title subjects
      if self.descMetadata.subject.title_info.length > 0
        doc['subject_title_tsim'] = []
        self.descMetadata.subject.title_info.title.each do |subject_title|
          doc['subject_title_tsim'] << subject_title
        end
        doc['subject_facet_ssim'].concat(doc['subject_title_tsim'])
      end

      # de-dupe various subject fields (needed for LCSH-style subjects from MODS OAI feeds)
      subjs_to_dedupe = %w(subject_topic_tsim subject_geo_nonhier_ssim subject_hiergeo_geojson_ssm subject_name_corporate_tsim subject_name_personal_tsim subject_name_conference_tsim subject_temporal_facet_ssim subject_title_tsim)
      subjs_to_dedupe.each do |subj_to_dedupe|
        doc[subj_to_dedupe] = doc[subj_to_dedupe].uniq if doc[subj_to_dedupe]
      end

      # remove values from subject_geo_nonhier_ssim
      # that are represented in subject_hiergeo_geojson_ssm
      if doc['subject_geo_nonhier_ssim'] && doc['subject_hiergeo_geojson_ssm']
        doc['subject_geo_nonhier_ssim'].each do |non_hier_geo_subj|
          doc['subject_hiergeo_geojson_ssm'].each do |hiergeo_geojson_feature|
            if hiergeo_geojson_feature.match(/#{non_hier_geo_subj}/)
              doc['subject_geo_nonhier_ssim'].delete(non_hier_geo_subj)
            end
          end
        end
      end

      doc['active_fedora_model_suffix_ssi'] = self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,'')

      doc['rights_ssm'] = []
      doc['license_ssm'] = []
      0.upto self.descMetadata.use_and_reproduction.length-1 do |index|
        case self.descMetadata.use_and_reproduction(index).displayLabel.first
          when 'rights'
            doc['rights_ssm'] << self.descMetadata.use_and_reproduction(index).first
          when 'license'
            doc['license_ssm'] << self.descMetadata.use_and_reproduction(index).first
        end
      end

      doc['restrictions_on_access_ssm'] = self.descMetadata.restriction_on_access

      doc['note_tsim'] = []
      doc['note_resp_tsim'] = []
      doc['note_date_tsim'] = []
      doc['note_performers_tsim'] = []
      doc['note_acquisition_tsim'] = []
      doc['note_ownership_tsim'] = []
      doc['note_citation_tsim'] = []
      doc['note_reference_tsim'] = []

      0.upto self.descMetadata.note.length-1 do |index|
        if self.descMetadata.note(index).type_at.first == 'statement of responsibility'
          doc['note_resp_tsim'].append(self.descMetadata.mods(0).note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'date'
          doc['note_date_tsim'].append(self.descMetadata.mods(0).note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'performers'
          doc['note_performers_tsim'].append(self.descMetadata.mods(0).note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'acquisition'
          doc['note_acquisition_tsim'].append(self.descMetadata.mods(0).note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'ownership'
          doc['note_ownership_tsim'].append(self.descMetadata.mods(0).note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'preferred citation'
          doc['note_citation_tsim'].append(self.descMetadata.mods(0).note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'citation/reference'
          doc['note_reference_tsim'].append(self.descMetadata.mods(0).note(index).first)
        else
          doc['note_tsim'].append(self.descMetadata.mods(0).note(index).first)
        end
      end


      0.upto self.descMetadata.physical_description.length-1 do |physical_index|
        0.upto self.descMetadata.physical_description(physical_index).note.length-1 do |note_index|
          if self.descMetadata.physical_description(physical_index).note(note_index).first != nil
            doc['note_tsim'].append(self.descMetadata.physical_description(physical_index).note(note_index).first)
          end
        end
      end

      doc['title_info_alternative_tsim'] = []
      doc['title_info_uniform_tsim'] = []
      doc['title_info_primary_trans_tsim'] = []
      doc['title_info_translated_tsim'] = []
      self.descMetadata.mods(0).title.each_with_index do |title_value,index|
        title_prefix = self.descMetadata.mods(0).title_info(index).nonSort[0] ? self.descMetadata.mods(0).title_info(index).nonSort[0] + ' ' : '' # shouldn't be adding space; see Trac ticket #101
        if self.descMetadata.mods(0).title_info(index).usage[0] == 'primary'
          if self.descMetadata.mods(0).title_info(index).type[0] == 'translated'
            if self.descMetadata.mods(0).title_info(index).display_label[0] == 'primary_display'
              doc['title_info_primary_tsi'] = title_prefix + title_value
              doc['title_info_primary_ssort'] = title_value
              doc['title_info_partnum_tsi'] = self.descMetadata.mods(0).title_info(index).part_number
              doc['title_info_partname_tsi'] = self.descMetadata.mods(0).title_info(index).part_name
            else
              doc['title_info_primary_trans_tsim'] << title_prefix + title_value
            end
          else
            doc['title_info_primary_tsi'] = title_prefix + title_value
            doc['title_info_primary_ssort'] = title_value
            doc['title_info_partnum_tsi'] = self.descMetadata.mods(0).title_info(index).part_number
            doc['title_info_partname_tsi'] = self.descMetadata.mods(0).title_info(index).part_name
          end
          if self.descMetadata.mods(0).title_info(index).supplied[0] == 'yes'
            doc['supplied_title_bs'] = 'true'
          end
        elsif self.descMetadata.mods(0).title_info(index).type[0] == 'alternative'
          doc['title_info_alternative_tsim'] << title_prefix + title_value
          if self.descMetadata.mods(0).title_info(index).supplied[0] == 'yes'
            doc['supplied_alternative_title_bs'] = 'true'
          end
          doc['title_info_alternative_label_ssm'] = self.descMetadata.mods(0).title_info(index).display_label
        elsif self.descMetadata.mods(0).title_info(index).type[0] == 'uniform'
          doc['title_info_uniform_tsim'] << title_prefix + title_value
        elsif self.descMetadata.mods(0).title_info(index).type[0] == 'translated'
          doc['title_info_translated_tsim'] << title_prefix + title_value
        end
      end

      doc['subtitle_tsim'] = self.descMetadata.title_info.subtitle


      if self.workflowMetadata
        doc['workflow_state_ssi'] = self.workflowMetadata.item_status.state
        doc['processing_state_ssi'] = self.workflowMetadata.item_status.processing
      end

      ActiveFedora::Base.find_in_batches('is_exemplary_image_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |exemplary_solr|
          doc['exemplary_image_ssi'] = exemplary_solr['id']
        }
      end

=begin
      ocr_text_normal = ''
      ocr_text_squished = ''
      ActiveFedora::Base.find_in_batches('is_image_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |image_file|
          if image_file['has_ocr_master_ssi'] == 'true'
            ocr_text_normal += image_file['full_ocr_ssi']
            ocr_text_squished += image_file['compressed_ocr_ssi']
          end

        }
      end

      doc['full_ocr_si'] = ocr_text_normal[0..10000] if ocr_text_normal.present?
      doc['full_ocr_ssi'] = ocr_text_normal[0..10000] if ocr_text_normal.present?
      doc['compressed_ocr_si'] = ocr_text_squished[0..10000] if ocr_text_squished.present?
      doc['compressed_ocr_ssi'] = ocr_text_squished[0..10000] if ocr_text_squished.present?
=end


      doc['ocr_tiv'] = self.plainText.content.squish if self.plainText.present?
      if self.scanData.present?
        scan_data_xml = Nokogiri::XML(self.scanData.content)
        doc['text_direction_ssi'] = scan_data_xml.xpath("//globalHandedness/page-progression").first.text
      end

      #Handle the case of multiple volumes...
      if self.class.name == 'Bplmodels::Book'
        volume_check = Bplmodels::Finder.getVolumeObjects(self.pid)
        if volume_check.present?
          doc['ocr_tiv'] = ''
          volume_check.each do |volume|
            #FIXME!!!
            volume_object = ActiveFedora::Base.find(volume['id']).adapt_to_cmodel
            doc['ocr_tiv'] += volume_object.plainText.content.squish + ' ' if volume_object.plainText.present?
          end
        end
      end


      if self.workflowMetadata.volume_match_md5s.present?
        doc['marc_md5_sum_ssi'] = self.workflowMetadata.volume_match_md5s.marc.first
        doc['iaMeta_matcher_md5_ssi'] = self.workflowMetadata.volume_match_md5s.iaMeta.first
      end

      if self.workflowMetadata.marked_for_deletion.present?
        doc['marked_for_deletion_bsi']  =  self.workflowMetadata.marked_for_deletion.first
        doc['marked_for_deletion_reason_ssi']  =  self.workflowMetadata.marked_for_deletion.reason.first
      end

      if self.workflowMetadata.item_designations.present?
        if self.workflowMetadata.item_designations(0).flagged_for_content.present?
          doc['flagged_content_ssi'] = self.workflowMetadata.item_designations(0).flagged_for_content
        end
      end


      #doc['all_text_timv'] = [self.descMetadata.abstract, main_title, self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,''),self.descMetadata.item_location(0).physical_location[0]]

      doc
    end

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the object
    #institution_pid => instituional access of this file
    #secondary_parent_pids => optional array of additional parent pids
    def self.mint(args)

      expected_aguments = [:parent_pid, :local_id, :local_id_type, :institution_pid, :secondary_parent_pids]
      expected_aguments.each do |arg|
        if !args.keys.include?(arg)
          raise "Mint called but missing parameter: #{arg}"
        end
       end

      #TODO: Duplication check here to prevent over-writes?

      args[:namespace_id] ||= ARK_CONFIG_GLOBAL['namespace_commonwealth_pid']
      args[:secondary_parent_pids] ||= []

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:parent_pid=>args[:parent_pid], :secondary_parent_pids=>args[:secondary_parent_pids], :namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>args[:namespace_id], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})

      begin
        as_json = JSON.parse(response.body)
      rescue => ex
        raise('Error in JSON response for minting an object pid.')
      end

      puts as_json['pid']

      #For some reason, the below stopped working suddenly?
=begin
      dup_check = ActiveFedora::Base.find(:pid=>as_json["pid"])
      if dup_check.present?
        return as_json["pid"]
      end
=end

      Bplmodels::ObjectBase.find_in_batches('id'=>as_json["pid"]) do |group|
        group.each { |solr_result|
          return as_json["pid"]
        }
      end

      object = self.new(:pid=>as_json["pid"])

      object.add_relationship(:is_member_of_collection, "info:fedora/" + args[:parent_pid])
      object.add_relationship(:administrative_set, "info:fedora/" + args[:parent_pid])

      args[:secondary_parent_pids].each do |other_collection_pid|
        object.add_relationship(:is_member_of_collection, "info:fedora/" + other_collection_pid)
      end

      object.add_oai_relationships

      object.label = args[:label] if args[:label].present?

      object.workflowMetadata.item_ark_info.ark_id = args[:local_id]
      object.workflowMetadata.item_ark_info.ark_type = args[:local_id_type]
      object.workflowMetadata.item_ark_info.ark_parent_pid = args[:parent_pid]

      object.read_groups = ["public"]
      object.edit_groups = ["superuser", "admin[#{args[:institution_pid]}]"] if args[:institution_pid]

      return object
    end

    def generate_thumbnail_url(config_hash=nil)
      if config_hash.present?
        return config_hash['url'] + '/ark:/' + config_hash["namespace_commonwealth_ark"].to_s + "/" + self.pid.split(':').last.to_s + "/thumbnail"
      end

      return ARK_CONFIG_GLOBAL['url'] + '/ark:/' + ARK_CONFIG_GLOBAL["namespace_commonwealth_ark"].to_s + "/" + self.pid.split(':').last.to_s + "/thumbnail"
    end

    def generate_uri
      return ARK_CONFIG_GLOBAL['url'] + '/ark:/' + ARK_CONFIG_GLOBAL["namespace_commonwealth_ark"].to_s + "/" + self.pid.split(':').last.to_s
    end

    def insert_marc(file_content)
      self.marc.content = file_content
      self.marc.mimeType = 'application/marc'
    end

    def insert_ia_meta(file_content)
      self.iaMeta.content = file_content
      self.iaMeta.mimeType = 'application/xml'
    end

    def insert_scan_data(file_content)
      self.scanData.content = file_content
      self.scanData.mimeType = 'application/xml'
    end

    def insert_plain_text(file_content)
      self.plainText.content = file_content
      self.plainText.mimeType = 'text/plain'
    end

    def insert_djvu_xml(file_content)
      self.djvuXML.content = file_content
      self.djvuXML.mimeType = 'application/xml'
    end

    def insert_abbyy(file_content)
      self.abbyy.content = file_content
      self.abbyy.mimeType = 'application/xml'
    end

    def simple_insert_file(file_path, file_name, ingest_source, institution_pid, original_file_location=nil, set_exemplary=nil)
      files_hash = []
      file_hash = {}
      file_hash[:datastream] = 'productionMaster'
      file_hash[:file_path] = file_path
      file_hash[:file_name] = file_name
      file_hash[:original_file_location] = original_file_location
      files_hash << file_hash

      insert_new_file(files_hash, ingest_source, institution_pid, set_exemplary)
    end

    # Expects a hash of the following keys
    # :file_path -> The path to the file
    # :datastream -> The datastream for the file
    # :file_name -> The name of the file
    def insert_new_file(files_hash, file_ingest_source, institution_pid, set_exemplary=nil)
      puts files_hash.to_s

      raise 'Missing insert_new_file params' if files_hash.first[:file_path].blank? || files_hash.first[:datastream].blank? || files_hash.first[:file_name].blank?

      production_master = files_hash.select{ |hash| hash[:datastream] == 'productionMaster' }.first

      if production_master[:file_name].include?('.tif')
        self.descMetadata.insert_media_type('image/tiff')
        self.descMetadata.insert_media_type('image/jpeg')
        self.descMetadata.insert_media_type('image/jp2')
        inserted_obj = self.insert_new_image_file(files_hash, institution_pid,set_exemplary)
      elsif production_master[:file_name].include?('.jp2')
          self.descMetadata.insert_media_type('image/jpeg')
          self.descMetadata.insert_media_type('image/jp2')
          inserted_obj = self.insert_new_image_file(files_hash, institution_pid,set_exemplary)
      elsif production_master[:file_name].include?('.mp3')
        self.descMetadata.insert_media_type('audio/mpeg')
        inserted_obj = self.insert_new_audio_file(files_hash, institution_pid)
      elsif production_master[:file_name].include?('.pdf')
        self.descMetadata.insert_media_type('application/pdf')
        inserted_obj = self.insert_new_document_file(files_hash, institution_pid,set_exemplary)
      elsif production_master[:file_name].include?('.epub')
        self.descMetadata.insert_media_type('application/epub+zip')
        inserted_obj = self.insert_new_ereader_file(files_hash, institution_pid)
      elsif production_master[:file_name].include?('.mobi')
        self.descMetadata.insert_media_type('application/x-mobipocket-ebook')
        inserted_obj = self.insert_new_ereader_file(files_hash, institution_pid)
      elsif production_master[:file_name].include?('daisy.zip')
        self.descMetadata.insert_media_type('application/zip')
        inserted_obj = self.insert_new_ereader_file(files_hash, institution_pid)
      else
        self.descMetadata.insert_media_type('image/jpeg')
        self.descMetadata.insert_media_type('image/jp2')
        inserted_obj = self.insert_new_image_file(files_hash, institution_pid,set_exemplary)
      end

      self.workflowMetadata.item_source.ingest_origin = file_ingest_source if self.workflowMetadata.item_source.ingest_origin.blank?
      files_hash.each do |file|
        original_file_location = file[:original_file_location]
        original_file_location ||= file[:file_path]
        self.workflowMetadata.insert_file_source(original_file_location,file[:file_name],file[:datastream])
      end
      inserted_obj
    end

    def insert_new_image_file(files_hash, institution_pid, set_exemplary)
      #raise 'insert new image called with no files or more than one!' if file.blank? || file.is_a?(Array)

      puts 'processing image of: ' + self.pid.to_s + ' with file_hash: ' + files_hash.to_s

      production_master = files_hash.select{ |hash| hash[:datastream] == 'productionMaster' }.first

      #uri_file_part = file
      #Fix common url errors
      #uri_file_part = URI::escape(uri_file_part) if uri_file_part.match(/^http/)

      image_file = Bplmodels::ImageFile.mint(:parent_pid=>self.pid, :local_id=>production_master[:file_name], :local_id_type=>'File Name', :label=>production_master[:file_name], :institution_pid=>institution_pid)

      if image_file.is_a?(String)
        #Bplmodels::ImageFile.find(last_image_file).delete
        #last_image_file = Bplmodels::ImageFile.mint(:parent_pid=>self.pid, :local_id=>final_file_name, :local_id_type=>'File Name', :label=>final_file_name, :institution_pid=>institution_pid)
        #return true
        return Bplmodels::ImageFile.find(image_file)
      end

      files_hash.each_with_index do |file, file_index|
        datastream = file[:datastream]


        image_file.send(datastream).content = ::File.open(file[:file_path])

        if file[:file_name].split('.').last.downcase == 'tif'
          image_file.send(datastream).mimeType = 'image/tiff'
        elsif file[:file_name].split('.').last.downcase == 'jpg'
          image_file.send(datastream).mimeType = 'image/jpeg'
        elsif file[:file_name].split('.').last.downcase == 'jp2'
          image_file.send(datastream).mimeType = 'image/jp2'
        else
          image_file.send(datastream).mimeType = 'image/jpeg'
        end

        image_file.send(datastream).dsLabel = file[:file_name].gsub('.tif', '').gsub('.jpg', '').gsub('.jpeg', '').gsub('.jp2', '')

        #FIXME!!!
        original_file_location = file[:original_file_location]
        original_file_location ||= file[:file_path]
        image_file.workflowMetadata.insert_file_source(original_file_location,file[:file_name],datastream)
        image_file.workflowMetadata.item_status.state = "published"
        image_file.workflowMetadata.item_status.state_comment = "Added via the ingest image object base method on " + Time.new.year.to_s + "/" + Time.new.month.to_s + "/" + Time.new.day.to_s


      end


        Bplmodels::ImageFile.find_in_batches('is_image_of_ssim'=>"info:fedora/#{self.pid}", 'is_preceding_image_of_ssim'=>'') do |group|
          group.each { |image_id|
            other_images_exist = true
            preceding_image = Bplmodels::ImageFile.find(image_id['id'])
            preceding_image.add_relationship(:is_preceding_image_of, "info:fedora/#{image_file.pid}", true)
            preceding_image.save
            image_file.add_relationship(:is_following_image_of, "info:fedora/#{image_id['id']}", true)
          }
        end

      image_file.add_relationship(:is_image_of, "info:fedora/" + self.pid)
      image_file.add_relationship(:is_file_of, "info:fedora/" + self.pid)

      if set_exemplary.nil? || set_exemplary
        if ActiveFedora::Base.find_with_conditions("is_exemplary_image_of_ssim"=>"info:fedora/#{self.pid}").blank?
          image_file.add_relationship(:is_exemplary_image_of, "info:fedora/" + self.pid)
        end
      end


      image_file.save

      image_file
    end

    def insert_new_ereader_file(files_hash, institution_pid)
      puts 'processing ereader of: ' + self.pid.to_s + ' with file_hash: ' + files_hash.to_s

      production_master = files_hash.select{ |hash| hash[:datastream] == 'productionMaster' }.first

      epub_file = Bplmodels::EreaderFile.mint(:parent_pid=>self.pid, :local_id=>production_master[:file_name], :local_id_type=>'File Name', :label=>production_master[:file_name], :institution_pid=>institution_pid)

      if epub_file.is_a?(String)
        #Bplmodels::ImageFile.find(last_image_file).delete
        #last_image_file = Bplmodels::ImageFile.mint(:parent_pid=>self.pid, :local_id=>final_file_name, :local_id_type=>'File Name', :label=>final_file_name, :institution_pid=>institution_pid)
        #return true
        return Bplmodels::EreaderFile.find(epub_file)
      end

      files_hash.each_with_index do |file, file_index|
        datastream = file[:datastream]


        epub_file.send(datastream).content = ::File.open(file[:file_path])

        if file[:file_name].split('.').last.downcase == 'epub'
          epub_file.send(datastream).mimeType = 'application/epub+zip'
        elsif file[:file_name].split('.').last.downcase == 'mobi'
          epub_file.send(datastream).mimeType = 'application/x-mobipocket-ebook'
        elsif file[:file_name].split('.').last.downcase == 'zip'
          epub_file.send(datastream).mimeType = 'application/zip'
        else
          epub_file.send(datastream).mimeType = 'application/epub+zip'
        end

        epub_file.send(datastream).dsLabel = file[:file_name].gsub('.epub', '').gsub('.mobi', '').gsub('.zip', '')

        #FIXME!!!
        original_file_location = file[:original_file_location]
        original_file_location ||= file[:file_path]
        epub_file.workflowMetadata.insert_file_source(original_file_location,file[:file_name],datastream)
        epub_file.workflowMetadata.item_status.state = "published"
        epub_file.workflowMetadata.item_status.state_comment = "Added via the ingest image object base method on " + Time.new.year.to_s + "/" + Time.new.month.to_s + "/" + Time.new.day.to_s


      end


      Bplmodels::EreaderFile.find_in_batches('is_ereader_of_ssim'=>"info:fedora/#{self.pid}", 'is_preceding_ereader_of_ssim'=>'') do |group|
        group.each { |ereader_id|
          other_images_exist = true
          preceding_ereader = Bplmodels::EreaderFile.find(ereader_id['id'])
          preceding_ereader.add_relationship(:is_preceding_ereader_of, "info:fedora/#{epub_file.pid}", true)
          preceding_ereader.save
          epub_file.add_relationship(:is_following_ereader_of, "info:fedora/#{ereader_id['id']}", true)
        }
      end

      epub_file.add_relationship(:is_ereader_of, "info:fedora/" + self.pid)
      epub_file.add_relationship(:is_file_of, "info:fedora/" + self.pid)

      epub_file.save

      epub_file
    end

    #FIXME: NOT UPDATED!
    def insert_new_audio_file(audio_file, institution_pid)
      raise 'audio file missing!' if audio_file.blank?

      uri_file_part = audio_file
      #Fix common url errors
      if uri_file_part.match(/^http/)
        #uri_file_part = uri_file_part.gsub(' ', '%20')
        uri_file_part = URI::escape(uri_file_part)
      end

      final_audio_name =  audio_file.gsub('\\', '/').split('/').last
      current_audio_file = Bplmodels::AudioFile.mint(:parent_pid=>self.pid, :local_id=>final_audio_name, :local_id_type=>'File Name', :label=>final_audio_name, :institution_pid=>institution_pid)
      if current_audio_file.is_a?(String)
        Bplmodels::AudioFile.find(current_audio_file).delete
        current_audio_file = Bplmodels::AudioFile.mint(:parent_pid=>self.pid, :local_id=>final_audio_name, :local_id_type=>'File Name', :label=>final_audio_name, :institution_pid=>institution_pid)
      end


      current_audio_file.productionMaster.content = open(uri_file_part)
      if audio_file.split('.').last.downcase == 'mp3'
        current_audio_file.productionMaster.mimeType = 'audio/mpeg'
      else
        current_audio_file.productionMaster.mimeType = 'audio/mpeg'
      end


      other_audio_exist = false
      Bplmodels::AudioFile.find_in_batches('is_audio_of_ssim'=>"info:fedora/#{self.pid}", 'is_preceding_audio_of_ssim'=>'') do |group|
        group.each { |audio|
          other_audio_exist = true
          preceding_audio = Bplmodels::AudioFile.find(audio['id'])
          preceding_audio.add_relationship(:is_preceding_audio_of, "info:fedora/#{current_audio_file.pid}", true)
          preceding_audio.save
          current_audio_file.add_relationship(:is_following_audio_of, "info:fedora/#{audio['id']}", true)
        }
      end

      current_audio_file.add_relationship(:is_audio_of, "info:fedora/" + self.pid)
      current_audio_file.add_relationship(:is_file_of, "info:fedora/" + self.pid)

      current_audio_file.workflowMetadata.insert_file_path(audio_file)
      current_audio_file.workflowMetadata.insert_file_name(final_audio_name)
      current_audio_file.workflowMetadata.item_status.state = "published"
      current_audio_file.workflowMetadata.item_status.state_comment = "Added via the ingest audio object base method on " + Time.new.year.to_s + "/" + Time.new.month.to_s + "/" + Time.new.day.to_s

      current_audio_file.save

      current_audio_file
    end

    def insert_new_document_file(files_hash, institution_pid, set_exemplary)
      production_master = files_hash.select{ |hash| hash[:datastream] == 'productionMaster' }.first

      #uri_file_part = file
      #Fix common url errors
      #uri_file_part = URI::escape(uri_file_part) if uri_file_part.match(/^http/)

      document_file = Bplmodels::DocumentFile.mint(:parent_pid=>self.pid, :local_id=>production_master[:file_name], :local_id_type=>'File Name', :label=>production_master[:file_name], :institution_pid=>institution_pid)

      if document_file.is_a?(String)
        #Bplmodels::ImageFile.find(last_image_file).delete
        #last_image_file = Bplmodels::ImageFile.mint(:parent_pid=>self.pid, :local_id=>final_file_name, :local_id_type=>'File Name', :label=>final_file_name, :institution_pid=>institution_pid)
        #return true
        return Bplmodels::DocumentFile.find(document_file)
      end

      files_hash.each_with_index do |file, file_index|
        datastream = file[:datastream]

        #Fix common url errors
        if file[:file_path].match(/^http/)
          document_file.send(datastream).content = ::File.open(URI::escape(file[:file_path]))
        else
          document_file.send(datastream).content = ::File.open(file[:file_path])
        end


        if file[:file_name].split('.').last.downcase == 'pdf'
          document_file.send(datastream).mimeType = 'application/pdf'
        else
          document_file.send(datastream).mimeType = 'application/pdf'
        end

        document_file.send(datastream).dsLabel = file[:file_name].gsub('.pdf', '')

        #FIXME!!!
        original_file_location = file[:original_file_location]
        original_file_location ||= file[:file_path]
        document_file.workflowMetadata.insert_file_source(original_file_location,file[:file_name],datastream)
        document_file.workflowMetadata.item_status.state = "published"
        document_file.workflowMetadata.item_status.state_comment = "Added via the ingest document object base method on " + Time.new.year.to_s + "/" + Time.new.month.to_s + "/" + Time.new.day.to_s


      end


      Bplmodels::DocumentFile.find_in_batches('is_document_of_ssim'=>"info:fedora/#{self.pid}", 'is_preceding_document_of_ssim'=>'') do |group|
        group.each { |document_id|
          preceding_document = Bplmodels::DocumentFile.find(document_id['id'])
          preceding_document.add_relationship(:is_preceding_document_of, "info:fedora/#{document_file.pid}", true)
          preceding_document.save
          preceding_document.add_relationship(:is_following_document_of, "info:fedora/#{document_id['id']}", true)
        }
      end

      document_file.add_relationship(:is_image_of, "info:fedora/" + self.pid)
      document_file.add_relationship(:is_file_of, "info:fedora/" + self.pid)

      if set_exemplary.nil? || set_exemplary
        if ActiveFedora::Base.find_with_conditions("is_exemplary_image_of_ssim"=>"info:fedora/#{self.pid}").blank?
          document_file.add_relationship(:is_exemplary_image_of, "info:fedora/" + self.pid)
        end
      end


      document_file.save

      document_file
    end

    def add_new_volume(pid)
      #raise 'insert new image called with no files or more than one!' if file.blank? || file.is_a?(Array)
      volume = Bplmodels::Volume.find(pid).adapt_to_cmodel
      placement_location = volume.descMetadata.title_info.part_number.first.match(/\d+/).to_s.to_i

      other_volumes_exist = false
      volume_placed = false
      queryed_placement_start_val = 0

      Bplmodels::Volume.find_in_batches('is_volume_of_ssim'=>"info:fedora/#{self.pid}", 'is_preceding_volume_of_ssim'=>'') do |group|
        group.each { |volume_id|
          if !volume_placed
            other_volumes_exist = true
            queryed_placement_end_val = volume_id['title_info_partnum_tsi'].match(/\d+/).to_s.to_i

            #Case of insert at end
            if volume_id['is_preceding_volume_of_ssim'].blank? && queryed_placement_end_val < placement_location
              preceding_volume = Bplmodels::Volume.find(volume_id['id'])
              preceding_volume.add_relationship(:is_preceding_volume_of, "info:fedora/#{pid}", true)
              preceding_volume.save
              volume.add_relationship(:is_following_volume_of, "info:fedora/#{volume_id['id']}", true)
              volume_placed = true
              #Case of only 1 element of volume 2... insert at beginning
            elsif volume_id['is_preceding_volume_of_ssim'].blank?
              following_volume = Bplmodels::Volume.find(volume_id['id'])
              following_volume.add_relationship(:is_following_volume_of, "info:fedora/#{pid}", true)

              volume.add_relationship(:is_preceding_volume_of, "info:fedora/#{volume_id['id']}", true)
              following_volume.save
              volume_placed = true
              #Case of multiple but insert at front
            elsif volume_id['is_following_volume_of_ssim'].blank? && queryed_placement_start_val < placement_location and queryed_placement_end_val > placement_location
              following_volume = Bplmodels::Volume.find(volume_id['id'])
              following_volume.add_relationship(:is_following_volume_of, "info:fedora/#{pid}", true)

              volume.add_relationship(:is_preceding_volume_of, "info:fedora/#{volume_id['id']}", true)
              following_volume.save
              volume_placed = true
              #Normal case
            elsif queryed_placement_start_val < placement_location and queryed_placement_end_val > placement_location
              following_volume = Bplmodels::Volume.find(volume_id['id'])
              preceding_volume = Bplmodels::Volume.find(volume_id['is_preceding_volume_of_ssim'].gsub('info:fedora/', ''))

              following_volume.remove_relationship(:is_following_volume_of, "info:fedora/#{preceding_volume.pid}", true)
              preceding_volume.remove_relationship(:is_preceding_volume_of, "info:fedora/#{following_volume.pid}", true)


              following_volume.add_relationship(:is_following_volume_of, "info:fedora/#{pid}", true)
              preceding_volume.add_relationship(:is_preceding_volume_of, "info:fedora/#{pid}", true)


              volume.add_relationship(:is_following_volume_of, "info:fedora/#{preceding_volume.pid}", true)
              volume.add_relationship(:is_preceding_volume_of, "info:fedora/#{following_volume.pid}", true)
              preceding_volume.save
              following_volume.save
              volume_placed = true
            end
          end

          queryed_placement_start_val = queryed_placement_end_val

        }
      end

      volume.add_relationship(:is_volume_of, "info:fedora/" + self.pid)

      #FIXME: Doesn't work with PDF?
      #FIXME: Do this better?
      if !other_volumes_exist
        ActiveFedora::Base.find_in_batches('is_exemplary_image_of_ssim'=>"info:fedora/#{pid}") do |group|
          group.each { |exemplary_solr|
            exemplary_image = Bplmodels::File.find(exemplary_solr['id']).adapt_to_cmodel
            exemplary_image.add_relationship(:is_exemplary_image_of, "info:fedora/" + self.pid)
            exemplary_image.save
          }
        end
      elsif placement_location == 1
        if ActiveFedora::Base.find_with_conditions("is_exemplary_image_of_ssim"=>"info:fedora/#{self.pid}").present?
          exemplary_to_remove_id = ActiveFedora::Base.find_with_conditions("is_exemplary_image_of_ssim"=>"info:fedora/#{self.pid}").first['id']
          exemplary_to_remove = ActiveFedora::Base.find(exemplary_to_remove_id).adapt_to_cmodel
          exemplary_to_remove.remove_relationship(:is_exemplary_image_of, "info:fedora/" + exemplary_to_remove_id)
        end

        ActiveFedora::Base.find_in_batches('is_exemplary_image_of_ssim'=>"info:fedora/#{pid}") do |group|
          group.each { |exemplary_solr|
            exemplary_image = Bplmodels::File.find(exemplary_solr['id']).adapt_to_cmodel
            exemplary_image.add_relationship(:is_exemplary_image_of, "info:fedora/" + self.pid)
            exemplary_image.save
          }
        end
      end


      volume.save

      volume
    end

    def deleteAllFiles
      Bplmodels::ImageFile.find_in_batches('is_image_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |solr_object|
          object = ActiveFedora::Base.find(solr_object['id']).adapt_to_cmodel
          object.delete
        }
      end

      Bplmodels::AudioFile.find_in_batches('is_audio_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |solr_object|
          object = ActiveFedora::Base.find(solr_object['id']).adapt_to_cmodel
          object.delete
        }
      end

      Bplmodels::DocumentFile.find_in_batches('is_document_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |solr_object|
          object = ActiveFedora::Base.find(solr_object['id']).adapt_to_cmodel
          object.delete
        }
      end
    end

    def derivative_service(is_new)
      response = Typhoeus::Request.post(DERIVATIVE_CONFIG_GLOBAL['url'] + "/processor/byobject.json", :params => {:pid=>self.pid, :new=>is_new, :environment=>Bplmodels.environment})
      puts response.body.to_s
      as_json = JSON.parse(response.body)

      if as_json['result'] == "false"
        pid = self.object.pid
        self.deleteAllFiles
        self.delete
        raise "Error Generating Derivatives For Object: " + pid
      end

      return true
    end

    def oai_thumbnail_service(is_new, urls, system_type, thumbnail_url=nil)
      response = Typhoeus::Request.post(DERIVATIVE_CONFIG_GLOBAL['url'] + "/processor/oaithumbnail.json", :params => {:pid=>self.pid, :new=>is_new, :environment=>Bplmodels.environment, :image_urls=>urls, :system_type=>system_type, :thumbnail_url=>thumbnail_url})
      as_json = JSON.parse(response.body)

      if as_json['result'] == "false"
        pid = self.object.pid
        self.delete
        raise "Error Generating OAI Thumbnail For Object: " + pid
      end

      return true
    end

    def cache_invalidate
      response = Typhoeus::Request.post(DERIVATIVE_CONFIG_GLOBAL['url'] + "/processor/objectcacheinvalidation.json", :params => {:pid=>self.pid, :environment=>Bplmodels.environment})
      as_json = JSON.parse(response.body)

      if as_json['result'] == "false"
        raise "Error Deleting the Cache! Server error!"
      end

      return true
    end


    def calculate_volume_match_md5s
      self.workflowMetadata.volume_match_md5s.marc = Digest::MD5.hexdigest(self.marc.content)
      self.workflowMetadata.volume_match_md5s.iaMeta = Digest::MD5.hexdigest(self.iaMeta.content.gsub(/<\/page_progression>.+$/, '').gsub(/<volume>.+<\/volume>/, ''))
    end

  end
end
