module Bplmodels
  class DatastreamInputFuncs

# these functions can be used to split names into subparts for <mods:name> and <mods:subject><mods:name>

# use for personal name headings e.g., <mods:name type="personal">
# returns personal name data as a hash which can be used to populate <mods:namePart> and <mads:namePart type="date">

    def self.persNamePartSplitter(inputstring)
      splitNamePartsHash = Hash.new
      unless inputstring =~ /\d{4}/
        splitNamePartsHash[:namePart] = inputstring
      else
        if inputstring =~ /\(.*\d{4}.*\)/
          splitNamePartsHash[:namePart] = inputstring
        else
          splitNamePartsHash[:namePart] = inputstring.gsub(/,[\d\- \.\w?]*$/,"")
          splitArray = inputstring.split(/.*,/)
          splitNamePartsHash[:datePart] = splitArray[1].strip
        end
      end
      return splitNamePartsHash
    end

# use for corporate name headings e.g., <mods:name type="corporate">
# returns corporate name data as an array which can be used to populate <mods:namePart> subparts
# (corporate name subparts are not differentiated by any attributes in the xml)
# (see http://id.loc.gov/authorities/names/n82139319.madsxml.xml for example)

    def self.corpNamePartSplitter(inputstring)
      splitNamePartsArray = Array.new
      unless inputstring =~ /[\S]{5}\./
        splitNamePartsArray << inputstring
      else
        while inputstring =~ /[\S]{5}\./
          snip = /[\S]{5}\./.match(inputstring).post_match
          subpart = inputstring.gsub(snip,"")
          splitNamePartsArray << subpart.gsub(/\.\z/,"").strip
          inputstring = snip
        end
        splitNamePartsArray << inputstring.gsub(/\.\z/,"").strip
      end
      return splitNamePartsArray
    end

    # a function to convert date data from OAI feeds into MODS-usable date data
    # assumes date values containing ";" have already been split
    # returns hash with :single_date, :date_range, :date_qualifier, and/or :date_note values
    def self.convert_to_mods_date(value)

      date_data = {} # create the hash to hold all the data
      source_date_string = value.strip # variable to hold original value

      # weed out obvious bad dates before processing
      if (value.match(/([Pp]re|[Pp]ost|[Bb]efore|[Aa]fter|[Uu]nknown|[Uu]ndated|n\.d\.)/)) ||
          (value.match(/\d\d\d\d-\z/)) || # 1975-
          (value.match(/\d\d-\d\d\/\d\d/)) || # 1975-09-09/10
          (value.match(/\d*\(\d*\)/)) ||  # 1975(1976)
          (value.scan(/\d\d\d\d/).length > 2) || # 1861/1869/1915
          (value.scan(/([Ee]arly|[Ll]ate|[Mm]id|[Ww]inter|[Ss]pring|[Ss]ummer|[Ff]all)/).length > 1) ||
          # or if data does not match any of these
          (!value.match(/(\d\dth [Cc]entury|\d\d\d-\?*|\d\d\d\?|\d\d\?\?|\d\d\d\d)/))
        date_data[:date_note] = source_date_string
      else
        # find date qualifier
        if value.include? '?'
          date_data[:date_qualifier] = 'questionable'
        elsif value.match(/\A[Cc]/)
          date_data[:date_qualifier] = 'approximate'
        elsif (value.match(/[\[\]]+/)) || (value.match(/[(][A-Za-z, \d]*[\d]+[A-Za-z, \d]*[)]+/)) # if [] or ()
          date_data[:date_qualifier] = 'inferred'
        end

        # remove unnecessary chars and words
        value = value.gsub(/[\[\]\(\)\.,']/,'')
        value = value.gsub(/(\b[Bb]etween\b|\bcirca\b|\bca\b|\Aca|\Ac)/,'').strip

        # differentiate between ranges and single dates
        if (value.scan(/\d\d\d\d/).length == 2) ||
            (value.include? '0s') ||          # 1970s
            (value.include? 'entury') ||      # 20th century
            (value.match(/(\A\d\d\d\?|\A\d\d\?\?|\A\d\d\d-\?*|\d\d\d\d-\d\z|\d\d\d\d\/[\d]{1,2}\z)/)) ||
            (value.match(/([Ee]arly|[Ll]ate|[Mm]id|[Ww]inter|[Ss]pring|[Ss]ummer|[Ff]all)/)) ||
            ((value.match(/\d\d\d\d-\d\d\z/)) && (value[-2..-1].to_i > 12)) # 1975-76 but NOT 1910-11

          # RANGES
          date_data[:date_range] = {}

          # deal with date strings with 2 4-digit year values separately
          if value.scan(/\d\d\d\d/).length == 2

            # convert weird span indicators ('or','and','||'), remove extraneous text
            value = value.gsub(/(or|and|\|\|)/,'-').gsub(/[A-Za-z\?\s]/,'')

            if value.match(/\A[12][\d]{3}-[01][\d]-[12][\d]{3}-[01][\d]\z/) # 1895-05-1898-01
              date_data_range_start = value[0..6]
              date_data_range_end = value[-7..-1]
            elsif value.match(/\A[12][\d]{3}\/[12][\d]{3}\z/) # 1987/1988
              date_data_range_start = value[0..3]
              date_data_range_end = value[-4..-1]
            else
              range_dates = value.split('-') # split the dates into an array
              range_dates.each_with_index do |range_date,index|
                # format the data properly
                if range_date.include? '/' # 11/05/1965
                  range_date_pieces = range_date.split('/')
                  range_date_piece_year = range_date_pieces.last
                  range_date_piece_month = range_date_pieces.first.length == 2 ? range_date_pieces.first : '0' + range_date_pieces.first
                  if range_date_pieces.length == 3
                    range_date_piece_day = range_date_pieces[1].length == 2 ? range_date_pieces[1] : '0' + range_date_pieces[1]
                  end
                  value_to_insert = range_date_piece_year + '-' + range_date_piece_month
                  value_to_insert << '-' + range_date_piece_day if range_date_piece_day
                elsif range_date.match(/\A[12][\d]{3}\z/)
                  value_to_insert = range_date
                end
                # add the data to the proper variable
                if value_to_insert
                  if index == 0
                    date_data_range_start = value_to_insert
                  else
                    date_data_range_end = value_to_insert
                  end
                end
              end
            end
          else
            # if there are 'natural language' range values, find, assign to var, then remove
            text_range = value.match(/([Ee]arly|[Ll]ate|[Mm]id|[Ww]inter|[Ss]pring|[Ss]ummer|[Ff]all)/).to_s
            if text_range.length > 0
              date_data[:date_qualifier] ||= 'approximate' # TODO - remove this??
              value = value.gsub(/#{text_range}/,'').strip
            end

            # deal with ranges for which 'natural language' range values are ignored
            if value.match(/\A1\d\?\?\z/) # 19??
              date_data_range_start = value[0..1] + '00'
              date_data_range_end = value[0..1] + '99'
            elsif value.match(/\A[12]\d\d-*\?*\z/) # 195? || 195-? || 195-
              date_data_range_start = value[0..2] + '0'
              date_data_range_end = value[0..2] + '9'
            elsif value.match(/\A[12]\d\d\d[-\/][\d]{1,2}\z/) # 1956-57 || 1956/57 || 1956-7
              if value.length == 7 && (value[5..6].to_i > value[2..3].to_i)
                date_data_range_start = value[0..3]
                date_data_range_end = value[0..1] + value[5..6]
              elsif value.length == 6 && (value[5].to_i > value[3].to_i)
                date_data_range_start = value[0..3]
                date_data_range_end = value[0..2] + value[5]
              end
              date_data[:date_note] = source_date_string if text_range.length > 0
            end
            # deal with ranges where text range values are evaluated
            value = value.gsub(/\?/,'').strip # remove question marks

            # centuries
            if value.match(/([12][\d]{1}th [Cc]entury|[12][\d]{1}00s)/) # 19th century || 1800s
              if value.match(/[12][\d]{1}00s/)
                century_prefix_date = value.match(/[12][\d]{1}/).to_s
              else
                century_prefix_date = (value.match(/[12][\d]{1}/).to_s.to_i-1).to_s
              end
              if text_range.match(/([Ee]arly|[Ll]ate|[Mm]id)/)
                if text_range.match(/[Ee]arly/)
                  century_suffix_dates = %w[00 39]
                elsif text_range.match(/[Mm]id/)
                  century_suffix_dates = %w[30 69]
                else
                  century_suffix_dates = %w[60 99]
                end
              end
              date_data_range_start = century_suffix_dates ? century_prefix_date + century_suffix_dates[0] : century_prefix_date + '00'
              date_data_range_end = century_suffix_dates ? century_prefix_date + century_suffix_dates[1] : century_prefix_date + '99'
            else
              # remove any remaining non-date text
              value.match(/[12][1-9][1-9]0s/) ? is_decade = true : is_decade = false # but preserve decade-ness
              remaining_text = value.match(/\D+/).to_s
              value = value.gsub(/#{remaining_text}/,'').strip if remaining_text.length > 0

              # decades
              if is_decade
                decade_prefix_date = value.match(/\A[12][1-9][1-9]/).to_s
                if text_range.match(/([Ee]arly|[Ll]ate|[Mm]id)/)
                  if text_range.match(/[Ee]arly/)
                    decade_suffix_dates = %w[0 3]
                  elsif text_range.match(/[Mm]id/)
                    decade_suffix_dates = %w[4 6]
                  else
                    decade_suffix_dates = %w[7 9]
                  end
                end
                date_data_range_start = decade_suffix_dates ? decade_prefix_date + decade_suffix_dates[0] : decade_prefix_date + '0'
                date_data_range_end = decade_suffix_dates ? decade_prefix_date + decade_suffix_dates[1] : decade_prefix_date + '9'
              else
                # single year ranges
                single_year_prefix = value.match(/[12][0-9]{3}/).to_s
                if text_range.length > 0
                  if text_range.match(/[Ee]arly/)
                    single_year_suffixes = %w[01 04]
                  elsif text_range.match(/[Mm]id/)
                    single_year_suffixes = %w[05 08]
                  elsif text_range.match(/[Ll]ate/)
                    single_year_suffixes = %w[09 12]
                  elsif text_range.match(/[Ww]inter/)
                    single_year_suffixes = %w[01 03]
                  elsif text_range.match(/[Ss]pring/)
                    single_year_suffixes = %w[03 05]
                  elsif text_range.match(/[Ss]ummer/)
                    single_year_suffixes = %w[06 08]
                  else text_range.match(/[F]all/)
                  single_year_suffixes = %w[09 11]
                  end
                  date_data_range_start = single_year_prefix + '-' + single_year_suffixes[0]
                  date_data_range_end = single_year_prefix + '-' + single_year_suffixes[1]
                end
              end
              # if possibly significant info removed, include as note
              date_data[:date_note] = source_date_string if remaining_text.length > 1
            end
          end

          # insert the values into the date_data hash
          if date_data_range_start && date_data_range_end
            date_data[:date_range][:start] = date_data_range_start
            date_data[:date_range][:end] = date_data_range_end
          else
            date_data[:date_note] ||= source_date_string
            date_data.delete :date_range
          end

        else
          # SINGLE DATES
          value = value.gsub(/\?/,'') # remove question marks
                                      # fix bad spacing (e.g. December 13,1985 || December 3,1985)
          value = value.insert(-5, ' ') if value.match(/[A-Za-z]* \d{6}/) || value.match(/[A-Za-z]* \d{5}/)

          # try to automatically parse single dates with YYYY && MM && DD values
          if Timeliness.parse(value).nil?
            # start further processing
            if value.match(/\A[12]\d\d\d-[01][0-9]\z/) # yyyy-mm
              date_data[:single_date] = value
            elsif value.match(/\A[01]?[1-9][-\/][12]\d\d\d\z/) # mm-yyyy || m-yyyy || mm/yyyy
              value = '0' + value if value.match(/\A[1-9][-\/][12]\d\d\d\z/) # m-yyyy || m/yyyy
              date_data[:single_date] = value[3..6] + '-' + value[0..1]
            elsif value.match(/\A[A-Za-z]{3,} [12]\d\d\d\z/) # April 1987 || Apr. 1987
              value = value.split(' ')
              if value[0].length == 3
                value_month = '%02d' % Date::ABBR_MONTHNAMES.index(value[0])
              else
                value_month = '%02d' % Date::MONTHNAMES.index(value[0])
              end
              date_data[:single_date] = value_month ? value[1] + '-' + value_month : value[1]
            elsif value.match(/\A[12]\d\d\d\z/) # 1999
              date_data[:single_date] = value
            else
              date_data[:date_note] = source_date_string
            end
          else
            date_data[:single_date] = Timeliness.parse(value).strftime("%Y-%m-%d")
          end

        end

      end

      # some final validation, just in case
      date_validation_array = []
      date_validation_array << date_data[:single_date] if date_data[:single_date]
      date_validation_array << date_data[:date_range][:start] if date_data[:date_range]
      date_validation_array << date_data[:date_range][:end] if date_data[:date_range]
      date_validation_array.each do |date_to_val|
        if date_to_val.length == '7'
          bad_date = true unless date_to_val[-2..-1].to_i.between?(1,12) && !date_to_val.nil?
        elsif
        date_to_val.length == '10'
          bad_date = true unless Timeliness.parse(value) && !date_to_val.nil?
        end
        if bad_date
          date_data[:date_note] ||= source_date_string
          date_data.delete :single_date if date_data[:single_date]
          date_data.delete :date_range if date_data[:date_range]
        end
      end

      # if the date slipped by all the processing somehow!
      if date_data[:single_date].nil? && date_data[:date_range].nil? && date_data[:date_note].nil?
        date_data[:date_note] = source_date_string
      end

      date_data

    end

    # retrieve data from Getty TGN to populate <mods:subject auth="tgn">
    def self.get_tgn_data(tgn_id)
      tgn_response = Typhoeus::Request.get('http://vocabsservices.getty.edu/TGNService.asmx/TGNGetSubject?subjectID=' + tgn_id, userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
      unless tgn_response.code == 500
        tgnrec = Nokogiri::XML(tgn_response.body)
        #puts tgnrec.to_s

        # coordinates
        if tgnrec.at_xpath("//Coordinates")
          coords = {}
          coords[:latitude] = tgnrec.at_xpath("//Latitude/Decimal").children.to_s
          coords[:longitude] = tgnrec.at_xpath("//Longitude/Decimal").children.to_s
        else
          coords = nil
        end

        hier_geo = {}

        #main term
        if tgnrec.at_xpath("//Terms/Preferred_Term/Term_Text")
          tgn_term_type = tgnrec.at_xpath("//Preferred_Place_Type/Place_Type_ID").children.to_s
          pref_term_langs = tgnrec.xpath("//Terms/Preferred_Term/Term_Languages/Term_Language/Language")
          # if the preferred term is the preferred English form, use that
          if pref_term_langs.children.to_s.include? "English"
            tgn_term = tgnrec.at_xpath("//Terms/Preferred_Term/Term_Text").children.to_s
          else # use the non-preferred term which is the preferred English form
            if tgnrec.xpath("//Terms/Non-Preferred_Term")
              non_pref_terms = tgnrec.xpath("//Terms/Non-Preferred_Term")
              non_pref_terms.each do |non_pref_term|
                non_pref_term_langs = non_pref_term.children.css("Term_Language")
                # have to loop through these, as sometimes languages share form
                non_pref_term_langs.each do |non_pref_term_lang|
                  if non_pref_term_lang.children.css("Preferred").children.to_s == "Preferred" && non_pref_term_lang.children.css("Language").children.to_s == "English"
                    tgn_term = non_pref_term.children.css("Term_Text").children.to_s
                  end
                end
              end
            end
          end
          # if no term is the preferred English form, just use the preferred term
          tgn_term ||= tgnrec.at_xpath("//Terms/Preferred_Term/Term_Text").children.to_s
        end
        if tgn_term && tgn_term_type
          case tgn_term_type
            when '29000/continent'
              hier_geo[:continent] = tgn_term
            when '81010/nation'
              hier_geo[:country] = tgn_term
            when '81161/province'
              hier_geo[:province] = tgn_term
            when '81165/region', '82193/union', '80005/semi-independent political entity'
              hier_geo[:region] = tgn_term
            when '81175/state', '81117/department', '82133/governorate'
              hier_geo[:state] = tgn_term
            when '81181/territory', '81021/dependent state', '81186/union territory'
              hier_geo[:territory] = tgn_term
            when '81115/county'
              hier_geo[:county] = tgn_term
            when '83002/inhabited place'
              hier_geo[:city] = tgn_term
            when '84251/neighborhood'
              hier_geo[:city_section] = tgn_term
            when '21471/island'
              hier_geo[:island] = tgn_term
            when '81101/area', '22101/general region', '83210/deserted settlement', '81501/historical region', '81126/national division'
              hier_geo[:area] = tgn_term
            else
              non_hier_geo = tgn_term
          end
        end

        # parent data for <mods:hierarchicalGeographic>
        if tgnrec.at_xpath("//Parent_String")
          parents = tgnrec.at_xpath("//Parent_String").children.to_s.split('], ')
          parents.each do |parent|
            if parent.include? '(continent)'
              hier_geo[:continent] = parent
            elsif parent.include? '(nation)'
              hier_geo[:country] = parent
            elsif parent.include? '(province)'
              hier_geo[:province] = parent
            elsif (parent.include? '(region)') || (parent.include? '(union)') || (parent.include? '(semi-independent political entity)')
              hier_geo[:region] = parent
            elsif (parent.include? '(state)') || (parent.include? '(department)') || (parent.include? '(governorate)')
              hier_geo[:state] = parent
            elsif (parent.include? '(territory)') || (parent.include? '(dependent state)') || (parent.include? '(union territory)')
              hier_geo[:territory] = parent
            elsif parent.include? '(county)'
              hier_geo[:county] = parent
            elsif parent.include? '(inhabited place)'
              hier_geo[:city] = parent
            elsif parent.include? '(neighborhood)'
              hier_geo[:city_section] = parent
            elsif parent.include? '(island)'
              hier_geo[:island] = parent
            elsif (parent.include? '(area)') || (parent.include? '(general region)') || (parent.include? '(deserted settlement)') || (parent.include? '(historical region)') || (parent.include? '(national division)')
              hier_geo[:area] = parent
            end
          end
          hier_geo.each do |k,v|
            hier_geo[k] = v.gsub(/ \(.*/,'')
          end
        end

        tgn_data = {}
        tgn_data[:coords] = coords
        tgn_data[:hier_geo] = hier_geo.length > 0 ? hier_geo : nil
        tgn_data[:non_hier_geo] = non_hier_geo ? non_hier_geo : nil

      else

        tgn_data = nil

      end

      return tgn_data

    end

    def parse_bing_api
      return_hash = {}

    end



    def self.tgn_id_from_term(term)
      return_hash = {}
      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0
      state_part = nil
      country_code = nil
      country_part = nil
      city_part = nil

      Geocoder.configure(:lookup => :bing,:api_key => 'Avmp8UMpfYiAJOYa2D-6_cykJoprZsvvN5YLv6SDalvN-BZnW9KMlCzjIV7Zrtmn',:timeout => 5)
      bing_api_result = Geocoder.search(term)

      #Use bing first and only for United States results...
      if bing_api_result.present? && bing_api_result.first.data["address"]["countryRegion"] == 'United States'
        if bing_api_result.first.data["address"]["addressLine"].present?
          return_hash[:keep_original_string] = true
          return_hash[:coordinates] = bing_api_result.first.data["geocodePoints"].first["coordinates"].first.to_s + ',' + bing_api_result.first.data["geocodePoints"].first["coordinates"].last.to_s
        end

        country_code = Bplmodels::Constants::COUNTRY_TGN_LOOKUP[bing_api_result.first.data["address"]["countryRegion"]]
        #country_part = Country.new(bing_api_result.first.data["adminArea1"]).name
        country_part = bing_api_result.first.data["address"]["countryRegion"]

        if country_code == 7012149
          state_part = Bplmodels::Constants::STATE_ABBR[bing_api_result.first.data["address"]["adminDistrict"]]
        else
          state_part = bing_api_result.first.data["address"]["adminDistrict"]
        end

        city_part = bing_api_result.first.data["address"]["locality"]

      #Use mapquest as a backup solution for non-found results or non-USA results
      else
        Geocoder.configure(:lookup => :mapquest,:api_key => 'Fmjtd%7Cluubn1utn0%2Ca2%3Do5-90b00a',:timeout => 5)
        mapquest_api_result = Geocoder.search(term)

        #If this call returned a result...
        if mapquest_api_result.present?

          if mapquest_api_result.first.data["street"].present?
            return_hash[:keep_original_string] = true
            return_hash[:coordinates] = mapquest_api_result.first.data['latLng']['lat'].to_s + ',' + mapquest_api_result.first.data['latLng']['lng'].to_s
          end

          country_code = Bplmodels::Constants::COUNTRY_TGN_LOOKUP[mapquest_api_result.first.data["adminArea1"]]
          country_part = Country.new(mapquest_api_result.first.data["adminArea1"]).name

          if country_code == 7012149
            state_part = Bplmodels::Constants::STATE_ABBR[mapquest_api_result.first.data["adminArea3"]]
          else
            state_part = mapquest_api_result.first.data["adminArea3"]
          end

          city_part = mapquest_api_result.first.data["adminArea5"]

        #Final fallback is google API. The best but we are limited to 2500 requests per day unless we pay the $10k a year premium account...
        #Note: If google cannot find street, it will return just city/state, like for "Salem Street and Paradise Road, Swampscott, MA, 01907"
        #Seems like it sets a partial_match=>true in the data section...
        else

          Geocoder.configure(:lookup => :google,:api_key => nil,:timeout => 5)
          google_api_result = Geocoder.search(term)

          #If this call returned no results, address lookup failed...
          if google_api_result.blank?
            return nil
          end

          #Types: street number, route, neighborhood, establishment, transit_station, bus_station
          google_api_result.first.data["address_components"].each do |result|
            if (result['types'] & ['street number', 'route', 'neighborhood', 'establishment', 'transit_station', 'bus_station']).present?
              return_hash[:keep_original_string] = google_api_result.first.data['partial_match'] unless google_api_result.first.data['partial_match'].blank?
              return_hash[:coordinates] = google_api_result.first.data['geometry']['location']['lat'].to_s + ',' + google_api_result.first.data['geometry']['location']['lng'].to_s
            elsif (result['types'] & ['country']).present?
              country_code = Bplmodels::Constants::COUNTRY_TGN_LOOKUP[result['long_name']]
              country_part = result['long_name']
            elsif (result['types'] & ['administrative_area_level_1']).present?
              state_part = result['long_name'].to_ascii
            elsif (result['types'] & ['locality']).present?
              city_part = result['long_name']
            end
          end


          end


      end



      top_match_term = ''
      match_term = nil

      if city_part.blank? && state_part.blank?
        # Limit to nations
        place_type = 81010
        #tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name="  + CGI.escape(term), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
        top_match_term = ''
        match_term = term.downcase
      elsif state_part.present? && city_part.blank? && country_code == 7012149
        #Limit to states
        place_type = 81175
        #tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(state_part), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
        top_match_term = country_part
        match_term = state_part.downcase
      elsif state_part.present? && city_part.blank?
        #Limit to regions
        place_type = 81165
        #tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(state_part), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
        top_match_term = country_part
        match_term = state_part.downcase
      elsif state_part.present? && city_part.present?
        #Limited to only inhabited places at the moment...
        place_type = 83002
        #tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(city_part), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
        top_match_term = state_part.downcase
        match_term = city_part.downcase
      else
        return nil
      end

      begin
        if retry_count > 0
          sleep(sleep_time)
        end
        retry_count = retry_count + 1

        tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(match_term), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])

      end until (tgn_response.code != 500 || retry_count == max_retry)

      unless tgn_response.code == 500
        puts 'match found!'
        parsed_xml = Nokogiri::Slop(tgn_response.body)

        if parsed_xml.Vocabulary.Count.text == '0'
          return nil
        end

        #If only one result, then not array. Otherwise array....
        if parsed_xml.Vocabulary.Subject.first.blank?
          subject = parsed_xml.Vocabulary.Subject

          current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').downcase.strip

          if current_term == match_term && subject.Preferred_Parent.text.to_ascii.downcase.include?("#{top_match_term}")
            return_hash[:tgn_id] = subject.Subject_ID.text
          end
        else
          parsed_xml.Vocabulary.Subject.each do |subject|
            current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').downcase.strip

            if current_term == match_term && subject.Preferred_Parent.text.to_ascii.downcase.include?("#{top_match_term}")
              return_hash[:tgn_id] = subject.Subject_ID.text
            end
          end
        end

      end

      if tgn_response.code == 500
        raise 'TGN Server appears to not be responding for Geographic query: ' + term
      end


      return return_hash

    end

    def self.tgn_id_from_term_mapquest(term)
      return_hash = {}
      mapquest_api_result = Geocoder.search(term)
      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0


      if mapquest_api_result.blank?
        return nil
      end

      return_hash[:longitude] = mapquest_api_result.first.data['latLng']['lng']
      return_hash[:latitude] = mapquest_api_result.first.data['latLng']['lat']

      country_code = Bplmodels::Constants::COUNTRY_TGN_LOOKUP[mapquest_api_result.first.data["adminArea1"]]
      country_part = Country.new(mapquest_api_result.first.data["adminArea1"]).name

      if country_code == 7012149
        state_part = Bplmodels::Constants::STATE_ABBR[mapquest_api_result.first.data["adminArea3"]]
      else
        state_part = mapquest_api_result.first.data["adminArea3"]
      end

      city_part = mapquest_api_result.first.data["adminArea5"]

      top_match_term = ''
      match_term = nil

      if city_part.blank? && state_part.blank?
        # Limit to nations
        place_type = 81010
        #tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name="  + CGI.escape(term), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
        top_match_term = ''
        match_term = term.downcase
      elsif state_part.present? && city_part.blank? && country_code == 7012149
        #Limit to states
        place_type = 81175
        #tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(state_part), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
        top_match_term = country_part
        match_term = state_part.downcase
      elsif state_part.present? && city_part.blank?
        #Limit to regions
        place_type = 81165
        #tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(state_part), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
        top_match_term = country_part
        match_term = state_part.downcase
      elsif state_part.present? && city_part.present?
        #Limited to only inhabited places at the moment...
        place_type = 83002
        #tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(city_part), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])
        top_match_term = state_part.downcase
        match_term = city_part.downcase
      else
        return nil
      end

      begin
        if retry_count > 0
          sleep(sleep_time)
        end
        retry_count = retry_count + 1

        tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(match_term), userpwd: BPL_CONFIG_GLOBAL['getty_un'] + ':' + BPL_CONFIG_GLOBAL['getty_pw'])

      end until (tgn_response.code != 500 || retry_count == max_retry)

      unless tgn_response.code == 500
        puts 'match found!'
        parsed_xml = Nokogiri::Slop(tgn_response.body)

        if parsed_xml.Vocabulary.Count.text == '0'
          return nil
        end

        #If only one result, then not array. Otherwise array....
        if parsed_xml.Vocabulary.Subject.first.blank?
          subject = parsed_xml.Vocabulary.Subject

          current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').downcase.strip

          if current_term == match_term && subject.Preferred_Parent.text.to_ascii.downcase.include?("#{top_match_term}")
            return_hash[:tgn_id] = subject.Subject_ID.text
          end
        else
          parsed_xml.Vocabulary.Subject.each do |subject|
            current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').downcase.strip

            if current_term == match_term && subject.Preferred_Parent.text.to_ascii.downcase.include?("#{top_match_term}")
              return_hash[:tgn_id] = subject.Subject_ID.text
            end
          end
        end

      end

      if tgn_response.code == 500
        raise 'TGN Server appears to not be responding for Geographic query: ' + term
      end


      return return_hash

    end

    def self.LCSHize(value)

      #Remove ending periods ... except when an initial
      if value.last == '.' && value[-2].match(/[^A-Z]/)
        value = value.slice(0..-2)
      end

      #Remove white space after and vefore  '--'
      value = value.gsub(/\s--/,'--')
      value = value.gsub(/--\s/,'--')

      #Ensure first work is capitalized
      value[0] = value.first.capitalize[0]

      #Strip an white space
      value = Bplmodels::DatastreamInputFuncs.strip_value(value)

      return value
    end


    def self.strip_value(value)
      if(value.blank?)
        return nil
      else
        if value.class == Float || value.class == Fixnum
          value = value.to_i.to_s
        end

        # Make sure it is all UTF-8 and not character encodings or HTML tags and remove any cariage returns
        return utf8Encode(value)
      end
    end

    def self.utf8Encode(value)
      return HTMLEntities.new.decode(ActionView::Base.full_sanitizer.sanitize(value.to_s.gsub(/\r?\n?\t/, ' ').gsub(/\r?\n/, ' ').gsub(/<br[\s]*\/>/,' '))).strip
    end

    def self.split_with_nils(value)
      if(value == nil)
        return ""
      else
        split_value = value.split("||")
        0.upto split_value.length-1 do |pos|
          split_value[pos] = strip_value(split_value[pos])
        end

        return split_value
      end
    end



  end
end
