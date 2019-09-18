module Bplmodels
  module DigitalObjectExport
    extend ActiveSupport::Concern
    included do

      def export_for_bpl_api
        export = {}
        titles = titles_for_export_hash
        related_items = related_items_for_export_hash
        physical_location = physical_location_for_export_hash
        rights = rights_for_export_hash
        export[:ark_id] = pid
        export[:created_at] = create_date
        export[:updated_at] = modified_date
        export[:admin_set] = {
            ark_id: admin_set.pid,
            name: admin_set.label
        }
        export[:is_member_of_collection] = collection.map { |col| { ark_id: col.pid, name: col.label } }
        export[:metastreams] = {}
        descriptive_metadata = {
            identifiers: identifiers_for_export_hash,
            title_primary: titles[:primary],
            title_other: titles[:other],
            name_role: names_for_export_hash,
            resource_type: rt_for_export_hash,
            resource_type_manuscript: (descMetadata.mods(0).type_of_resource.manuscript.first == 'yes' ? true : nil),
            genre: genres_for_export_hash,
            digital_origin: descMetadata.mods(0).physical_description.digital_origin[0].presence,
            origin_event: descMetadata.mods(0).origin_info.event_type[0].presence,
            place_of_publication: descMetadata.mods(0).origin_info.place.place_term[0].presence,
            publisher: descMetadata.mods(0).origin_info.publisher[0].presence,
            date: dates_for_export_hash,
            edition: descMetadata.mods(0).origin_info.edition[0].presence,
            issuance: descMetadata.mods(0).origin_info.issuance[0].presence,
            frequency: descMetadata.mods(0).origin_info.frequency[0].presence,
            language: langs_for_export_hash,
            note: notes_for_export_hash,
            extent: descMetadata.mods(0).physical_description(0).extent.join(' '),
            abstract: descMetadata.mods(0).abstract.join(' '),
            toc: descMetadata.mods(0).table_of_contents.join(' '),
            toc_url: descMetadata.mods(0).table_of_contents.href[0].presence,
            subject: subjects_for_export_hash,
            scale: descMetadata.mods(0).subject.cartographics.scale.presence,
            projection: descMetadata.mods(0).subject.cartographics.projection[0].presence,
            host_collection: related_items[:host],
            series: related_items[:series],
            subseries: related_items[:subseries],
            related_referenced_by_url: related_items[:referenced_by_url],
            related_constituent: related_items[:constituent],
            physical_location: { label: physical_location[:label], name_type: 'corporate' },
            physical_location_department: physical_location[:department],
            physical_location_shelf_locator: physical_location[:shelf_locator],
            rights: rights[:rights],
            license: rights[:license],
            access_restrictions: descMetadata.mods(0).restriction_on_access[0].presence
        }
        export[:metastreams][:descriptve] = descriptive_metadata.compact.reject { |_k, v| v.blank? }
        export[:metastreams][:administrative] = {
            description_standard: descMetadata.mods(0).record_info.description_standard[0],
            flagged: (workflowMetadata.item_designations(0).flagged_for_content[0] == "true" ? true : false),
            destination_site: workflowMetadata.destination.site,
            harvestable: if workflowMetadata.item_status.harvestable[0] =~ /[Ff]alse/ ||
                workflowMetadata.item_status.harvestable[0] == false
                           false
                         else
                           true
                         end,
            access_edit_group: rightsMetadata.access(2).machine.group
        }.compact
        export[:metastreams][:workflow] = {
            ingest_filepath: workflowMetadata.source.ingest_filepath[0],
            ingest_filename: workflowMetadata.source.ingest_filename[0],
            ingest_datastream: workflowMetadata.source.ingest_datastream[0],
            processing_state: workflowMetadata.item_status.processing[0],
            publishing_state: workflowMetadata.item_status.state[0]
        }.compact
        { digital_object: export }
      end

      def identifiers_for_export_hash
        ids = []
        descMetadata.identifier.each_with_index.map do |id, index|
          id_hash = { label: id, type: descMetadata.identifier(index).type_at[0] }
          id_hash[:invalid] = true if descMetadata.identifier(index).invalid[0] == 'yes'
          ids << id_hash
        end

        ids
      end

      def titles_for_export_hash
        titles = { other: [] }
        descMetadata.mods(0).title.each_with_index do |title, index|
          title_prefix = self.descMetadata.mods(0).title_info(index).nonSort[0].presence || ''
          supplied = descMetadata.mods(0).title_info(index).supplied[0].presence
          title_id = descMetadata.mods(0).title_info(index).valueURI[0].presence
          title_hash = {
              label: title_prefix + title,
              subtitle: descMetadata.mods(0).title_info(index).subtitle[0].presence,
              type: descMetadata.mods(0).title_info(index).type[0],
              display: descMetadata.mods(0).title_info(index).display_label[0].presence,
              usage: descMetadata.mods(0).title_info(index).usage[0].presence,
              supplied: (supplied == 'yes' ? true : nil),
              language: descMetadata.mods(0).title_info(index).language[0].presence,
              authority_code: descMetadata.mods(0).title_info(index).authority[0].presence,
              id_from_auth: (title_id ? title_id.match(/[A-Za-z0-9]*\z/).to_s : nil),
              part_number: descMetadata.mods(0).title_info(index).part_number[0].presence,
              part_name: descMetadata.mods(0).title_info(index).part_name[0].presence
          }
          title_hash.compact!
          if title_hash[:display] == "primary_display"
            titles[:primary] = title_hash
          else
            titles[:other] << title_hash
          end
        end
        titles
      end

      def names_for_export_hash
        names = []
        descMetadata.mods(0).name.each_with_index do |_name, index|
          nametype = descMetadata.mods(0).name(index).type[0].presence
          name_id = descMetadata.mods(0).name(index).valueURI[0].presence
          name_hash = {
              name_type: nametype,
              authority_code: descMetadata.mods(0).name(index).authority[0].presence,
              id_from_auth: (name_id ? name_id.match(/[A-Za-z0-9]*\z/).to_s : nil)
          }
          name_hash[:label] = if nametype == 'corporate'
                                descMetadata.mods(0).name(index).namePart.join(". ").gsub(/\.\./,'.')
                              else
                                descMetadata.mods(0).name(index).namePart.join(", ")
                              end
          roles = []
          descMetadata.mods(0).name(index).role.each_with_index do |_role, role_index|
            role_id = descMetadata.mods(0).name(index).role.text.valueURI[role_index]
            role_hash = {
                label: descMetadata.mods(0).name(index).role.text[role_index],
                authority_code: 'relators',
                id_from_auth: (role_id ? role_id.match(/[A-Za-z0-9]*\z/).to_s : nil)
            }
            roles << role_hash.compact
          end
          roles.each do |role_hash|
            names << { name: name_hash.compact, role: role_hash}
          end
        end
        names
      end

      def rt_for_export_hash
        resource_types = []
        descMetadata.mods(0).type_of_resource.each do |rt|
          rt_hash = case rt
                    when 'still image'
                      { rt.to_s => 'img' }
                    when 'text'
                      { rt.to_s => 'txt' }
                    when 'moving image'
                      { rt.to_s => 'mov' }
                    when 'three dimensional object'
                      { 'Artifact' => 'art' }
                    when 'cartographic'
                      { rt.to_s => 'car' }
                    when 'mixed material'
                      { rt.to_s => 'mix' }
                    when 'sound recording', 'sound recording-nonmusical', 'sound recording-musical'
                      { 'Audio' => 'aud' }
                    when 'notated music'
                      { rt.to_s => 'not' }
                    end
          resource_types << rt_hash
        end
        resource_types.map! do |rt_hash|
          { label: rt_hash.keys.first.capitalize,
            authority_code: 'resourceTypes',
            id_from_auth: rt_hash.values.first }
        end
      end

      def genres_for_export_hash
        genres = []
        descMetadata.mods(0).genre.each_with_index do |genre, index|
          genre_id = descMetadata.mods(0).genre(index).valueURI[0].presence
          genre_hash = {
              label: genre,
              authority_code: descMetadata.mods(0).genre(index).authority[0].presence,
              id_from_auth: (genre_id ? genre_id.match(/[A-Za-z0-9]*\z/).to_s : nil)
          }
          genre_hash[:basic] = true if descMetadata.mods(0).genre(index).displayLabel[0] == 'general'
          genres << genre_hash.compact
        end
        genres
      end

      def dates_for_export_hash
        dates = {}
        date_types = %i[dates_created dates_issued dates_copyright]
        date_types.each do |date_type|
          range = descMetadata.mods(0).date(0).send(date_type, 0).point.blank? ? false : true
          start_date = {}
          end_date = {}
          descMetadata.mods(0).date(0).send(date_type).each_with_index do |date, index|
            date_hash = { date_value: date,
                          qualifier: descMetadata.mods(0).date(0).send(date_type, index).qualifier[0].presence }
            if descMetadata.mods(0).date(0).send(date_type, index).point[0] == 'end'
              end_date = date_hash
            else
              start_date = date_hash
            end
          end
          dates[date_type.to_s.gsub(/dates_/, '').to_sym] = date_to_edtf(start_date, end_date, range)
        end
        dates.compact
      end

      # TODO: how to do BC dates?
      # TODO: how to handle inferred dates?
      # TODO: validate EDTF dates?
      # @param start_date_w_qualifier [Hash] e.g. { date_value: '1975', qualifier: 'questionable' }
      def date_to_edtf(start_date_w_qualifier, end_date_w_qualifier = {}, range = false)
        output = []
        [start_date_w_qualifier, end_date_w_qualifier].each_with_index do |date_hash, index|
          qualifier_string = ''
          qualifier_string = '?' if date_hash[:qualifier] == 'questionable'
          qualifier_string = '~' if date_hash[:qualifier] == 'approximate'
          date_value_string = if range && index.zero? && !date_hash[:date_value]
                                ''
                              elsif range && !date_hash[:date_value]
                                '..'
                              else
                                date_hash[:date_value]
                              end
          puts "INDEX is #{index} AND DATE HASH is: #{date_hash} AND DATE V STRING is: #{date_value_string}"
          output << (date_value_string ? date_value_string + qualifier_string : nil)
        end
        puts "DATE TO EDTF FINISHED OK"
        output.compact.join('/').presence
      end

      def langs_for_export_hash
        langs = []
        descMetadata.mods(0).language.each_with_index do |_lang, index|
          lang_term = descMetadata.mods(0).language(index).language_term[0]
          lang_id = descMetadata.mods(0).language(index).language_term.lang_val_uri[0].presence
          lang_hash = {
              label: lang_term,
              authority_code: (lang_id ? 'iso639-2' : nil),
              id_from_auth: (lang_id ? lang_id.match(/[A-Za-z0-9]*\z/).to_s : nil)
          }
          langs << lang_hash.compact
        end
        langs
      end

      def notes_for_export_hash
        notes = []
        descMetadata.mods(0).note.each_with_index do |note, index|
          note_hash = {
              label: note,
              type: descMetadata.mods(0).note(index).type_at[0].presence
          }
          notes << note_hash.compact
        end
        descMetadata.mods(0).physical_description(0).note.each do |note|
          notes << { label: note, type: 'physical description' }
        end
        descMetadata.mods(0).date(0).date_other.each do |date_other|
          notes << { label: date_other, type: 'date' }
        end
        notes
      end

      # TODO: multipart subjects from OAI providers -- can't use same auth for all subelements,
      #       weird geographics with display labels
      def subjects_for_export_hash
        subjects = { topic: [], name: [], geo: [], title: [], temporal: [], date: [] }
        descMetadata.mods(0).subject.each_with_index do |_subject, index|
          this_subject = descMetadata.mods(0).subject(index)
          authority = this_subject.authority[0]
          id_from_auth = this_subject.valueURI[0]
          multipart = false

          # check if this is a multipart subject, like we get from MODS records in OAI feeds
          multipart = true if this_subject.topic.length > 1 ||
              (this_subject.topic.any? &&
                  (this_subject.geographic.any? || this_subject.genre.any? ||
                      this_subject.temporal.any? || this_subject.name.any? ||
                      this_subject.title_info.any?))

          if multipart == false
            # TOPICS
            if this_subject.topic.any?
              this_subject.topic.each do |topic|
                subjects[:topic] << { label: topic, authority_code: authority, id_from_auth: id_from_auth }
              end
            end

            # NAMES
            if this_subject.name.any?
              this_subject.name.each do |_name|
                authority = this_subject.name.authority[0]
                id_from_auth = this_subject.name.value_uri[0]
                nametype = this_subject.name.type[0]
                name_value = if nametype == 'corporate'
                               this_subject.name.name_part_actual.join(". ").gsub(/\.\./,'.')
                             else
                               this_subject.name.name_part_actual.join(", ")
                             end
                subjects[:name] << { label: name_value, name_type: nametype,
                                     authority_code: authority, id_from_auth: id_from_auth }
              end
            end

            # TITLE
            if this_subject.title_info.title.any?
              authority = this_subject.title_info.authority[0]
              id_from_auth = this_subject.title_info.valueURI[0]
              title_type = this_subject.title_info.type[0]
              subjects[:title] << { label: this_subject.title_info.title[0], type: title_type,
                                    authority_code: authority, id_from_auth: id_from_auth }
            end

            # TEMPORAL / DATE
            if this_subject.temporal.any?
              range = this_subject.temporal.point.blank? ? false : true
              start_date = {}
              end_date = {}
              this_subject.temporal.each_with_index do |date, date_index|
                date_hash = { date_value: date }
                if this_subject.temporal.point[date_index] == 'end'
                  end_date = date_hash
                else
                  start_date = date_hash
                end
              end
              subjects[:temporal] << date_to_edtf(start_date, end_date, range)
            end
          else
            # concat all children LCSH style (Foo--Bar)
            topic_label = this_subject[0].gsub(/\n/, '').strip.gsub(/[\s]{2,}/, '--')
            subjects[:topic] << { label: topic_label, authority_code: authority, id_from_auth: id_from_auth }
          end

          # GEOGRAPHIC
          if this_subject.cartographics.coordinates.any? || this_subject.geographic.any? ||
              this_subject.hierarchical_geographic.any?
            coords = this_subject.cartographics.coordinates[0]
            geo_hash = {
                authority_code: authority,
                id_from_auth: id_from_auth,
                coordinates: coords
            }
            raw_geo = this_subject.geographic[0]
            continent = this_subject.hierarchical_geographic.continent[0]
            country = this_subject.hierarchical_geographic.country[0]
            province = this_subject.hierarchical_geographic.province[0]
            region = this_subject.hierarchical_geographic.region[0]
            state = this_subject.hierarchical_geographic.state[0]
            territory = this_subject.hierarchical_geographic.territory[0]
            county = this_subject.hierarchical_geographic.county[0]
            city = this_subject.hierarchical_geographic.city[0]
            city_section = this_subject.hierarchical_geographic.city_section[0]
            island = this_subject.hierarchical_geographic.island[0]
            area = this_subject.hierarchical_geographic.area[0]
            geo_hash[:label] = raw_geo || city_section || city || island || county || territory ||
                area || state || region || province || country || continent
            subjects[:geo] << geo_hash if geo_hash[:label] || coords
          end
        end

        # remove all nils, parse URIs for IDs
        %i[topic name geo title].each do |subject_type|
          subjects[subject_type].map!(&:compact)
          subjects[subject_type].each do |subject|
            subject[:id_from_auth] = subject[:id_from_auth].match(/[A-Za-z0-9]*\z/).to_s if subject[:id_from_auth]
          end
        end
        subjects.reject { |_k, v| v.blank? }
      end

      def related_items_for_export_hash
        related_items = { host: [], referenced_by_url: [] }
        descMetadata.mods(0).related_item.each_with_index do |_ri, index|
          ri_type = self.descMetadata.mods(0).related_item(index).type[0]
          ri_title = (descMetadata.mods(0).related_item(index).title_info.nonSort[0].presence || '') + (descMetadata.mods(0).related_item(index).title_info.title[0].presence || '')
          case ri_type
          when 'host'
            related_items[:host] << ri_title
          when 'series'
            related_items[:series] = ri_title
          when 'isReferencedBy'
            related_items[:referenced_by_url] << descMetadata.mods(0).related_item(index).href[0]
          when 'constituent'
            related_items[:constituent] = ri_title
          end
        end
        if descMetadata.related_item.subseries.any?
          ri_title = (descMetadata.mods(0).related_item.subseries(0).title_info.nonSort[0].presence || '') + descMetadata.mods(0).related_item.subseries(0).title_info.title[0]
          related_items[:subseries] = ri_title
        end
        related_items.compact.reject { |_k, v| v.blank? }
      end

      def physical_location_for_export_hash
        physical_location = {
            label: descMetadata.mods(0).item_location.physical_location[0],
            department: descMetadata.mods(0).item_location.holding_simple.copy_information.sub_location[0],
            shelf_locator: descMetadata.mods(0).item_location.holding_simple.copy_information.shelf_locator[0]
        }
        physical_location.compact
      end

      def rights_for_export_hash
        rights_hash = { license: [] }
        descMetadata.mods(0).use_and_reproduction.each_with_index do |rights, index|
          case descMetadata.mods(0).use_and_reproduction(index).displayLabel[0]
          when 'rights'
            rights_hash[:rights] = rights
          when 'license'
            rights_hash[:license] << { label: rights }
          end
        end
        rights_hash.reject { |_k, v| v.blank? }
      end
    end
  end
end