module Bplmodels
  class ObjectBase < ActiveFedora::Base
    # To change this template use File | Settings | File Templates.
    include ActiveFedora::Auditable

    def save
      super()
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
            case self.descMetadata.date(0).dates_created(index).point[0]
              when nil
                dates_static << date
                doc['date_type_ssm'] << 'dateCreated'
                doc['date_start_qualifier_ssm'] = self.descMetadata.date(0).dates_created(index).qualifier[0]
              when 'start'
                dates_start << date
                doc['date_type_ssm'] << 'dateCreated'
                doc['date_start_qualifier_ssm'] = self.descMetadata.date(0).dates_created(index).qualifier[0]
              when 'end'
                dates_end << date
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
                doc['date_start_qualifier_ssm'] = self.descMetadata.date(0).dates_issued(index).qualifier[0]
              when 'start'
                dates_start << date
                doc['date_type_ssm'] << 'dateIssued'
                doc['date_start_qualifier_ssm'] = self.descMetadata.date(0).dates_issued(index).qualifier[0]
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
                doc['date_start_qualifier_ssm'] = self.descMetadata.date(0).dates_copyright(index).qualifier[0]
              when 'start'
                dates_start << date
                doc['date_type_ssm'] << 'copyrightDate'
                doc['date_start_qualifier_ssm'] = self.descMetadata.date(0).dates_copyright(index).qualifier[0]
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

      end

      doc['abstract_tsim'] = self.descMetadata.abstract
      doc['table_of_contents_tsi'] = self.descMetadata.table_of_contents[0]

      doc['genre_basic_tsim'] = self.descMetadata.genre_basic
      doc['genre_specific_tsim'] = self.descMetadata.genre_specific

      doc['genre_basic_ssim'] = self.descMetadata.genre_basic
      doc['genre_specific_ssim'] = self.descMetadata.genre_specific

      doc['identifier_local_other_tsim'] = self.descMetadata.local_other
      doc['identifier_local_call_tsim'] = self.descMetadata.local_call

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

      doc['pubplace_tsim'] = self.descMetadata.origin_info.place.place_term

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
          doc['name_personal_role_tsim'].append(self.descMetadata.mods(0).name(index).role.text[0])
        elsif self.descMetadata.mods(0).name(index).type[0] == "corporate"
          corporate_name = self.descMetadata.mods(0).name(index).namePart.join(". ").gsub(/\.\./,'.')
          # TODO -- do we need the conditional below?
          # don't think corp names have dates
          if self.descMetadata.mods(0).name(index).date.length > 0
            doc['name_corporate_tsim'].append(corporate_name + ", " + self.descMetadata.mods(0).name(index).date[0])
          else
            doc['name_corporate_tsim'].append(corporate_name)
          end
          doc['name_corporate_role_tsim'].append(self.descMetadata.mods(0).name(index).role.text[0])
        else

          if self.descMetadata.mods(0).name(index).date.length > 0
            doc['name_generic_tsim'].append(self.descMetadata.mods(0).name(index).namePart[0] + ", " + self.descMetadata.mods(0).name(index).date[0])
          else
            doc['name_generic_tsim'].append(self.descMetadata.mods(0).name(index).namePart[0])
          end
          doc['name_generic_role_tsim'].append(self.descMetadata.mods(0).name(index).role.text[0])
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
      doc['subject_geographic_tsim'] = subject_geo

      # hierarchical geo
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

      doc['subject_geo_country_tsim'] = country
      doc['subject_geo_country_ssim'] = country
      doc['subject_geo_province_tsim'] = province
      doc['subject_geo_province_ssim'] = province
      doc['subject_geo_region_tsim'] = region
      doc['subject_geo_region_ssim'] = region
      doc['subject_geo_state_tsim'] = state
      doc['subject_geo_state_ssim'] = state
      doc['subject_geo_territory_tsim'] = territory
      doc['subject_geo_territory_ssim'] = territory
      doc['subject_geo_county_tsim'] = county
      doc['subject_geo_county_ssim'] = county
      doc['subject_geo_city_tsim'] = city
      doc['subject_geo_city_ssim'] = city
      doc['subject_geo_citysection_tsim'] = city_section
      doc['subject_geo_citysection_ssim'] = city_section
      doc['subject_geo_island_tsim'] = island
      doc['subject_geo_island_ssim'] = island
      doc['subject_geo_area_tsim'] = area
      doc['subject_geo_area_ssim'] = area

      # coordinates
      doc['subject_coordinates_geospatial'] = self.descMetadata.subject.cartographics.coordinates

      # add " (county)" to county values for better faceting
      county_facet = []
      if county.length > 0
        county.each do |county_value|
          county_facet << county_value + ' (county)'
        end
      end

      # add all subject-geo values to subject-geo facet field (remove dupes)
      doc['subject_geographic_ssim'] = (country + province + region + state + territory + area + island + county_facet + city + city_section + subject_geo).uniq

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
            subject_temporal_start.length > 4 ? subject_date_range_start.append(subject_temporal_start[0..3]) : subject_date_range_start.append(subject_temporal_start)
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
            subject_temporal_end.length > 4 ? subject_date_range_end.append(subject_temporal_end[0..3]) : subject_date_range_end.append(subject_temporal_end)
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
              doc['subject_temporal_facet_ssim'].append(date_start + '-' + subject_date_range_end[index])
            else
              doc['subject_temporal_facet_ssim'].append(date_start)
            end
          end
        end

        doc['subject_facet_ssim'].concat(doc['subject_temporal_facet_ssim'])

      end


      doc['active_fedora_model_suffix_ssi'] = self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,'')

      doc['use_and_reproduction_ssm'] = self.descMetadata.use_and_reproduction
      doc['restrictions_on_access_ssm'] = self.descMetadata.restriction_on_access

      doc['note_tsim'] = []
      doc['note_resp_tsim'] = []
      doc['note_date_tsim'] = []

      0.upto self.descMetadata.note.length-1 do |index|
        if self.descMetadata.note(index).type_at.first == 'statement of responsibility'
          doc['note_resp_tsim'].append(self.descMetadata.note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'date'
          doc['note_date_tsim'].append(self.descMetadata.note(index).first)
        else
          doc['note_tsim'].append(self.descMetadata.note(index).first)
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
      self.descMetadata.mods(0).title.each_with_index do |title_value,index|
        title_prefix = self.descMetadata.mods(0).title_info(index).nonSort[0] ? self.descMetadata.mods(0).title_info(index).nonSort[0] + ' ' : ''
        if self.descMetadata.mods(0).title_info(index).usage[0] == 'primary'
          doc['title_info_primary_tsi'] = title_prefix + title_value
          doc['title_info_primary_ssort'] = title_value
          if self.descMetadata.mods(0).title_info(index).supplied[0] == 'yes'
            doc['supplied_title_bs'] = 'true'
          end
        else
          doc['title_info_alternative_tsim'] << title_prefix + title_value
          if self.descMetadata.mods(0).title_info(index).supplied[0] == 'yes'
            doc['supplied_alternative_title_bs'] = 'true'
          end
        end
      end

      doc['subtitle_tsim'] = self.descMetadata.title_info.subtitle

      if self.collection
        if self.collection.institutions
          doc['institution_pid_si'] = self.collection.institutions.pid
        end
      end

      if self.workflowMetadata
        doc['workflow_state_ssi'] = self.workflowMetadata.item_status.state
      end

      if self.exemplary_image.first != nil && self.exemplary_image.first.pid != nil
        # keep both for now, we will eventually phase out exemplary_image_ss
        doc['exemplary_image_ss'] = self.exemplary_image.first.pid
        doc['exemplary_image_ssi'] = self.exemplary_image.first.pid
      end

      if self.workflowMetadata.marked_for_deletion.present?
        doc['marked_for_deletion_bsi']  =  self.workflowMetadata.marked_for_deletion.first
        doc['marked_for_deletion_reason_ssi']  =  self.workflowMetadata.marked_for_deletion.reason.first
      end




      #doc['all_text_timv'] = [self.descMetadata.abstract, main_title, self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,''),self.descMetadata.item_location(0).physical_location[0]]

      doc
    end

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    def self.mint(args)

      #TODO: Duplication check here to prevent over-writes?

      args[:namespace_id] ||= ARK_CONFIG_GLOBAL['namespace_commonwealth_pid']

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:parent_pid=>args[:parent_pid], :namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>args[:namespace_id], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})
      as_json = JSON.parse(response.body)

      dup_check = ActiveFedora::Base.find(:pid=>as_json["pid"])
      if dup_check.present?
        return as_json["pid"]
      end

      puts 'pid is: ' + as_json["pid"]
      object = self.new(:pid=>as_json["pid"])

      return object
    end

    def generate_thumbnail_url
      return ARK_CONFIG_GLOBAL['url'] + '/ark:/' + ARK_CONFIG_GLOBAL["namespace_commonwealth_ark"].to_s + "/" + self.pid.split(':').last.to_s + "/thumbnail"
    end

    def generate_uri
      return ARK_CONFIG_GLOBAL['url'] + '/ark:/' + ARK_CONFIG_GLOBAL["namespace_commonwealth_ark"].to_s + "/" + self.pid.split(':').last.to_s
    end

  end
end