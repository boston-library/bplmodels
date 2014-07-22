module Bplmodels
  class ObjectBase < ActiveFedora::Base
    # To change this template use File | Settings | File Templates.
    include ActiveFedora::Auditable

    has_many :exemplary_image, :class_name => "Bplmodels::File", :property=> :is_exemplary_image_of

    has_many :image_files, :class_name => "Bplmodels::ImageFile", :property=> :is_image_of

    has_many :audio_files, :class_name => "Bplmodels::AudioFile", :property=> :is_image_of

    has_many :document_files, :class_name => "Bplmodels::DocumentFile", :property=> :is_image_of

    def save
      super()
    end

    def delete
      Bplmodels::File.find_in_batches('is_file_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |solr_file|
          file = Bplmodels::File.find(solr_file['id']).adapt_to_cmodel
          file.delete
        }
      end
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

      doc['identifier_local_other_tsim'] = self.descMetadata.local_other
      doc['identifier_local_call_tsim'] = self.descMetadata.local_call
      doc['identifier_local_barcode_tsim'] = self.descMetadata.local_barcode

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

      doc['edition_tsim'] = self.descMetadata.origin_info.edition

      doc['issuance_tsim'] = self.descMetadata.origin_info.issuance

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

      # scale
      doc['subject_scale_tsim'] = self.descMetadata.subject.cartographics.scale

      # coordinates / bbox
      if self.descMetadata.subject.cartographics.coordinates.length > 0
        self.descMetadata.subject.cartographics.coordinates.each do |coordinates|
          if coordinates.scan(/[\s]/).length == 3
            doc['subject_bounding_box_geospatial'] ||= []
            doc['subject_bounding_box_geospatial'] << coordinates
          else
            doc['subject_coordinates_geospatial'] ||= []
            doc['subject_coordinates_geospatial'] << coordinates
          end
        end
      end
      # doc['subject_coordinates_geospatial'] = self.descMetadata.subject.cartographics.coordinates # use this if we want to mix bbox and point data

      #Blacklight-maps esque placename_coords
      0.upto self.descMetadata.subject.length-1 do |subject_index|
       if self.descMetadata.mods(0).subject(subject_index).cartographics.present? && self.descMetadata.mods(0).subject(subject_index).cartographics.scale.blank?
         place_name = "Results"
         if self.descMetadata.mods(0).subject(subject_index).authority == ['tgn']
           place_locations = []
           self.descMetadata.mods(0).subject(subject_index).hierarchical_geographic[0].split("\n").each do |split_geo|
             split_geo = split_geo.strip
             place_locations << split_geo if split_geo.present? && !split_geo.include?('North and Central America') && !split_geo.include?('United States')
           end
           place_name = place_locations.reverse.join(', ')
         else
           place_name = self.descMetadata.mods(0).subject(subject_index).geographic.first
         end

         doc['subject_blacklight_maps_ssim'] = "#{place_name}-|-#{self.descMetadata.mods(0).subject(subject_index).cartographics.coordinates[0].split(',').first}-|-#{self.descMetadata.mods(0).subject(subject_index).cartographics.coordinates[0].split(',').last}"
       end
      end

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

      doc['active_fedora_model_suffix_ssi'] = self.rels_ext.model.class.to_s.gsub(/\A[\w]*::/,'')

      doc['use_and_reproduction_ssm'] = self.descMetadata.use_and_reproduction
      doc['restrictions_on_access_ssm'] = self.descMetadata.restriction_on_access

      doc['note_tsim'] = []
      doc['note_resp_tsim'] = []
      doc['note_date_tsim'] = []
      doc['note_performers_tsim'] = []

      0.upto self.descMetadata.note.length-1 do |index|
        if self.descMetadata.note(index).type_at.first == 'statement of responsibility'
          doc['note_resp_tsim'].append(self.descMetadata.mods(0).note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'date'
          doc['note_date_tsim'].append(self.descMetadata.mods(0).note(index).first)
        elsif self.descMetadata.note(index).type_at.first == 'performers'
          doc['note_performers_tsim'].append(self.descMetadata.mods(0).note(index).first)
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
        doc['processing_state_ssi'] = self.workflowMetadata.item_status.processing
      end

      ActiveFedora::Base.find_in_batches('is_exemplary_image_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |exemplary_solr|
          doc['exemplary_image_ss'] = exemplary_solr['id']
          doc['exemplary_image_ssi'] = exemplary_solr['id']
        }
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
    def self.mint(args)

      #TODO: Duplication check here to prevent over-writes?

      args[:namespace_id] ||= ARK_CONFIG_GLOBAL['namespace_commonwealth_pid']

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:parent_pid=>args[:parent_pid], :namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>args[:namespace_id], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})
      as_json = JSON.parse(response.body)

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
      object.add_oai_relationships

      object.label = args[:label] if args[:label].present?

      object.workflowMetadata.item_ark_info.ark_id = args[:local_id]
      object.workflowMetadata.item_ark_info.ark_type = args[:local_id_type]
      object.workflowMetadata.item_ark_info.ark_parent_pid = args[:parent_pid]

      object.read_groups = ["public"]
      object.edit_groups = ["superuser", "admin[#{args[:institution_pid]}]"] if args[:institution_pid]

      return object
    end

    def generate_thumbnail_url
      return ARK_CONFIG_GLOBAL['url'] + '/ark:/' + ARK_CONFIG_GLOBAL["namespace_commonwealth_ark"].to_s + "/" + self.pid.split(':').last.to_s + "/thumbnail"
    end

    def generate_uri
      return ARK_CONFIG_GLOBAL['url'] + '/ark:/' + ARK_CONFIG_GLOBAL["namespace_commonwealth_ark"].to_s + "/" + self.pid.split(':').last.to_s
    end

    # Expects a hash of the following keys
    # :file_path -> The path to the file
    # :datastream -> The datastream for the file
    # :file_name -> The name of the file
    def insert_new_file(files_hash, file_ingest_source, institution_pid)
      puts files_hash.to_s

      raise 'Missing insert_new_file params' if files_hash.first[:file_path].blank? || files_hash.first[:datastream].blank? || files_hash.first[:file_name].blank?

      production_master = files_hash.select{ |hash| hash[:datastream] == 'productionMaster' }.first

      if production_master[:file_name].include?('.tif')
        self.descMetadata.insert_media_type('image/tiff')
        self.descMetadata.insert_media_type('image/jpeg')
        self.descMetadata.insert_media_type('image/jp2')
        self.insert_new_image_file(files_hash, institution_pid)
      elsif production_master[:file_name].include?('.mp3')
        self.descMetadata.insert_media_type('audio/mpeg')
        self.insert_new_audio_file(files_hash, institution_pid)
      elsif production_master[:file_name].include?('.pdf')
        self.descMetadata.insert_media_type('application/pdf')
        self.insert_new_document_file(files_hash, institution_pid)
      else
        self.descMetadata.insert_media_type('image/jpeg')
        self.descMetadata.insert_media_type('image/jp2')
        self.insert_new_image_file(files_hash, institution_pid)
      end

      self.workflowMetadata.item_source.ingest_origin = file_ingest_source
      files_hash.each do |file|
        self.workflowMetadata.insert_file_source(file[:file_path],file[:file_name],file[:datastream])
      end
    end

    def insert_new_image_file(files_hash, institution_pid)
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
        return true
      end

      files_hash.each_with_index do |file, file_index|
        datastream = file[:datastream]


        image_file.send(datastream).content = open(file[:file_path])

        if file[:file_name].split('.').last.downcase == 'tif'
          image_file.send(datastream).mimeType = 'image/tiff'
        elsif file[:file_name].split('.').last.downcase == 'jpg'
          image_file.send(datastream).mimeType = 'image/jpeg'
        else
          image_file.send(datastream).mimeType = 'image/jpeg'
        end

        image_file.send(datastream).dsLabel = file[:file_name]

        #FIXME!!!
        image_file.workflowMetadata.insert_file_source(file[:file_path],file[:file_name],datastream)
        image_file.workflowMetadata.item_status.state = "published"
        image_file.workflowMetadata.item_status.state_comment = "Added via the ingest image object base method on " + Time.new.year.to_s + "/" + Time.new.month.to_s + "/" + Time.new.day.to_s


      end


        other_images_exist = false
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
      image_file.add_relationship(:is_exemplary_image_of, "info:fedora/" + self.pid) unless other_images_exist

      image_file.save

      image_file
    end

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

    #FIXME: Cases of images and PDF?
    def insert_new_document_file(document_file, institution_pid)
      raise 'document file missing!' if document_file.blank?

      puts 'processing document of: ' + self.pid.to_s + ' with file: ' + document_file

      uri_file_part = document_file

      #Fix common url errors
      if uri_file_part.match(/^http/)
        #uri_file_part = uri_file_part.gsub(' ', '%20')
        uri_file_part = URI::escape(uri_file_part)
      end

      final_document_name =  document_file.gsub('\\', '/').split('/').last
      current_document_file = Bplmodels::DocumentFile.mint(:parent_pid=>self.pid, :local_id=>final_document_name, :local_id_type=>'File Name', :label=>final_document_name, :institution_pid=>institution_pid)
      if current_document_file.is_a?(String)
        Bplmodels::DocumentFile.find(current_document_file).delete
        current_document_file = Bplmodels::DocumentFile.mint(:parent_pid=>self.pid, :local_id=>final_document_name, :local_id_type=>'File Name', :label=>final_document_name, :institution_pid=>institution_pid)
        #return true
      end

      current_document_file.productionMaster.content = open(uri_file_part)
      if document_file.split('.').last.downcase == 'pdf'
        current_document_file.productionMaster.mimeType = 'application/pdf'
      else
        current_document_file.productionMaster.mimeType = 'application/pdf'
      end

      current_page = 0
      total_colors = 0
      until total_colors > 1 do
        img = Magick::Image.read(uri_file_part + '[' + current_page.to_s + ']'){
          self.quality = 100
          self.density = 200
        }.first
        total_colors = img.total_colors
        current_page = current_page + 1
      end

      #This is horrible. But if you don't do this, some PDF files won't come out right at all.
      #Multiple attempts have failed to fix this but perhaps the bug will be patched in ImageMagick.
      #To duplicate, one can use the PDF files at: http://libspace.uml.edu/omeka/files/original/7ecb4dc9579b11e2b53ccc2040e58d36.pdf
      img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

      thumb = img.resize_to_fit(300,300)

      current_document_file.thumbnail300.content = thumb.to_blob { self.format = "jpg" }
      current_document_file.thumbnail300.mimeType = 'image/jpeg'

      Bplmodels::DocumentFile.find_in_batches('is_document_of_ssim'=>"info:fedora/#{self.pid}", 'is_preceding_document_of_ssim'=>'') do |group|
        group.each { |document_solr|
          other_document_exist = true
          preceding_document = Bplmodels::DocumentFile.find(document_solr['id'])
          preceding_document.add_relationship(:is_preceding_document_of, "info:fedora/#{current_document_file.pid}", true)
          preceding_document.save
          current_document_file.add_relationship(:is_following_document_of, "info:fedora/#{document_solr['id']}", true)
        }
      end

      #TODO: Fix this in the image file object?
      other_exemplary_exist = false
      Bplmodels::File.find_in_batches('is_exemplary_image_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |exemplary_solr|
          other_exemplary_exist = true
        }
      end

      current_document_file.add_relationship(:is_document_of, "info:fedora/" + self.pid)
      current_document_file.add_relationship(:is_file_of, "info:fedora/" + self.pid)

      current_document_file.add_relationship(:is_exemplary_image_of, "info:fedora/" + self.pid) unless other_exemplary_exist

      current_document_file.workflowMetadata.insert_file_path(document_file)
      current_document_file.workflowMetadata.insert_file_name(final_document_name)
      current_document_file.workflowMetadata.item_status.state = "published"
      current_document_file.workflowMetadata.item_status.state_comment = "Added via the ingest document object base method on " + Time.new.year.to_s + "/" + Time.new.month.to_s + "/" + Time.new.day.to_s

      current_document_file.save

      img.destroy!
      current_document_file
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

  end
end
