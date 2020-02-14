module Bplmodels
  module DescMetadataExport
    extend ActiveSupport::Concern
    included do

      def identifiers_for_export_hash
        ids = []
        descMetadata.identifier.each_with_index.map do |id, index|
          id_type = descMetadata.identifier(index).type_at[0]
          next if id_type == 'uri' && self.class != Bplmodels::OAIObject
          id_hash = { label: id, type: id_type }
          id_hash[:invalid] = true if descMetadata.identifier(index).invalid[0] == 'yes'
          ids << id_hash
        end
        ids
      end

      def titles_for_export_hash
        titles = { other: [] }
        descMetadata.mods(0).title.each_with_index do |title, index|
          primary = false
          title_prefix = self.descMetadata.mods(0).title_info(index).nonSort[0].presence || ''
          supplied = descMetadata.mods(0).title_info(index).supplied[0].presence
          title_id = descMetadata.mods(0).title_info(index).valueURI[0].presence
          display_label = descMetadata.mods(0).title_info(index).display_label[0].presence
          usage = descMetadata.mods(0).title_info(index).usage[0].presence
          primary = true if display_label == 'primary_display' || (display_label && usage == 'primary')
          title_hash = {
            label: title_prefix + title,
            subtitle: descMetadata.mods(0).title_info(index).subtitle[0].presence,
            type: if primary
                    descMetadata.mods(0).title_info(index).type[0]
                  else
                    descMetadata.mods(0).title_info(index).type[0].presence || 'alternative'
                  end,
            display: primary ? 'primary' : display_label,
            usage: usage,
            supplied: (supplied == 'yes' ? true : nil),
            language: descMetadata.mods(0).title_info(index).language[0].presence,
            authority_code: descMetadata.mods(0).title_info(index).authority[0].presence,
            id_from_auth: (title_id ? title_id.match(/[A-Za-z0-9]*\z/).to_s : nil),
            part_number: descMetadata.mods(0).title_info(index).part_number[0].presence,
            part_name: descMetadata.mods(0).title_info(index).part_name[0].presence
          }
          title_hash.compact!
          if primary
            titles[:primary] = title_hash
          else
            titles[:other] << title_hash
          end
        end
        titles.reject { |_k, v| v.blank? }
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
          # beware of empty <mods:namePart/>
          name_parts = descMetadata.mods(0).name(index).namePart.reject { |np| np.blank? }
          name_hash[:label] = if nametype == 'corporate'
                                name_parts.join(". ").gsub(/\.\./,'.')
                              else
                                name_parts.join(", ")
                              end
          roles = []
          descMetadata.mods(0).name(index).role.each_with_index do |_role, role_index|
            role_id = descMetadata.mods(0).name(index).role.text.valueURI[role_index]
            role_hash = {
              label: descMetadata.mods(0).name(index).role.text[role_index],
              authority_code: 'marcrelator',
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
        # volume stuff from DC2 is deprecated
        # volumes = Bplmodels::Finder.getVolumeObjects(pid)
        # if volumes.present?
        #   genres << {
        #     label: 'Serial publications',
        #     authority_code: 'lcgft',
        #     id_from_auth: 'gf2014026174',
        #     basic: true
        #   }
        # end
        genres
      end

      def dates_for_export_hash
        @inferred = false
        dates = {}
        date_types = %i[dates_created dates_issued dates_copyright]
        date_types.each do |date_type|
          range = descMetadata.mods(0).date(0).send(date_type, 0).point.blank? ? false : true
          start_date_hash = {}
          end_date_hash = {}
          descMetadata.mods(0).date(0).send(date_type).each_with_index do |date, index|
            qualifier = descMetadata.mods(0).date(0).send(date_type, index).qualifier[0].presence
            @inferred = true if qualifier == 'inferred'
            date_hash = { date_value: date,
                          qualifier: qualifier }
            if descMetadata.mods(0).date(0).send(date_type, index).point[0] == 'end'
              end_date_hash = date_hash
            else
              start_date_hash = date_hash
            end
          end
          dates[date_type.to_s.gsub(/dates_/, '').to_sym] = date_to_edtf(start_date_hash, end_date_hash, range)
        end
        dates.compact
      end
      
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
          output << (date_value_string ? date_value_string + qualifier_string : nil)
        end
        edtf_date = output.compact.join('/').presence
        return edtf_date if edtf_date.nil?
        raise "EDTF::ParserError - date could not be parsed: #{edtf_date}" unless EDTF.parse(edtf_date)
        edtf_date
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
        notes << { label: 'This date is inferred.', type: 'date'} if @inferred
        notes
      end

      def td_for_export_hash
        ia_metadata = iaMeta.content
        return nil unless ia_metadata
        td_data = ia_metadata.body.match(/<page-progression>[a-z]*/)
        if td_data
          td = td_data.to_s.match(/[a-z]*\z/)
        end
        td ? td.to_s.insert(1, 't') : nil
      end

      # TODO: weird geographics with display labels
      def subjects_for_export_hash
        subjects = { topics: [], names: [], geos: [], titles: [], temporals: [], dates: [] }
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
                subjects[:topics] << { label: topic, authority_code: authority, id_from_auth: id_from_auth }
              end
            end

            # NAMES
            if this_subject.name.any?
              this_subject.name.each do |_name|
                authority = this_subject.name.authority[0] || authority
                id_from_auth = this_subject.name.value_uri[0] || id_from_auth
                nametype = this_subject.name.type[0]
                name_parts = this_subject.name.name_part_actual.reject { |np| np.blank? }
                name_value = if nametype == 'corporate'
                               name_parts.join(". ").gsub(/\.\./,'.')
                             else
                               name_parts.join(", ")
                             end
                subjects[:names] << { label: name_value, name_type: nametype,
                                     authority_code: authority, id_from_auth: id_from_auth }
              end
            end

            # TITLE
            if this_subject.title_info.title.any?
              authority = this_subject.title_info.authority[0] || authority
              id_from_auth = this_subject.title_info.valueURI[0] || id_from_auth
              title_type = this_subject.title_info.type[0]
              subjects[:titles] << { label: this_subject.title_info.title[0], type: title_type,
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
              subjects[:dates] << date_to_edtf(start_date, end_date, range)
            end
          else
            # concat all children LCSH style (Foo--Bar)
            topic_label = this_subject[0].gsub(/\n/, '').strip.gsub(/[\s]{2,}/, '--')
            subjects[:topics] << { label: topic_label, authority_code: authority, id_from_auth: id_from_auth }
          end

          # GEOGRAPHIC
          if this_subject.cartographics.coordinates.any? || this_subject.geographic.any? ||
              this_subject.hierarchical_geographic.any?
            geo_hash = {
              authority_code: authority,
              id_from_auth: id_from_auth
            }
            geo_display_label = this_subject.geographic.display_label.first
            coords = this_subject.cartographics.coordinates[0]
            if coords&.match(/,/)
              geo_hash[:coordinates] = coords
            elsif coords
              geo_hash[:bounding_box] = coords
            end
            geo_data = {}
            geo_data[:raw_geo] = this_subject.geographic[0]
            geo_data[:area] = this_subject.hierarchical_geographic.area[0]
            geo_data[:island] = this_subject.hierarchical_geographic.island[0]
            geo_data[:city_section] = this_subject.hierarchical_geographic.city_section[0]
            geo_data[:city] = this_subject.hierarchical_geographic.city[0]
            geo_data[:county] = this_subject.hierarchical_geographic.county[0]
            geo_data[:province] = this_subject.hierarchical_geographic.province[0]
            geo_data[:territory] = this_subject.hierarchical_geographic.territory[0]
            geo_data[:state] = this_subject.hierarchical_geographic.state[0]
            geo_data[:region] = this_subject.hierarchical_geographic.region[0]
            geo_data[:country] = this_subject.hierarchical_geographic.country[0]
            geo_data[:continent] = this_subject.hierarchical_geographic.continent[0]
            geo_hash[:area_type] = geo_display_label.presence
            geo_data.each do |k, v|
              break if geo_hash[:label]
              if v
                geo_hash[:label] = v
                geo_hash[:area_type] ||= k.to_s unless k == :raw_geo # TODO test set type from displayLabel
              end
            end
            subjects[:geos] << geo_hash if geo_hash[:label] || coords
          end
        end

        # remove all nils, parse URIs for IDs
        %i[topics names geos titles].each do |subject_type|
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
        if descMetadata.related_item.subseries.subsubseries.any?
          ri_title = (descMetadata.mods(0).related_item.subseries.subsubseries(0).title_info.nonSort[0].presence || '') + descMetadata.mods(0).related_item.subseries.subsubseries(0).title_info.title[0]
          related_items[:subsubseries] = ri_title
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
        rights_hash = {}
        descMetadata.mods(0).use_and_reproduction.each_with_index do |use, index|
          case descMetadata.mods(0).use_and_reproduction(index).displayLabel[0]
          when 'rights'
            rights_hash[:rights] = use
          when 'license'
            rights_hash[:license] = { label: use }
            if use.include?('Creative Commons')
              cc_term_code = use.match(/\s[BYNCDSA-]{2,}/).to_s.strip.downcase
              rights_hash[:license][:uri] = "https://creativecommons.org/licenses/#{cc_term_code}/4.0" if cc_term_code.present?
            end
          end
        end
        rights_hash.reject { |_k, v| v.blank? }
      end
    end
  end
end
