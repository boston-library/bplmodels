#!/bin/env ruby
# encoding: utf-8
require 'htmlentities'
require 'hydra-file_characterization'
module Bplmodels
  class DatastreamInputFuncs

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
          splitNamePartsHash[:datePart] = splitArray[1].strip if splitArray[1]
        end
      end
      return splitNamePartsHash
    end

    # use for corporate name headings e.g., <mods:name type="corporate">
    # returns corporate name data as an array which can be used to populate <mods:namePart> subparts
    # (corporate name subparts are not differentiated by any attributes in the xml)
    # (see http://id.loc.gov/authorities/names/n82139319.madsxml.xml for example)
    # Note: (?!\)) part is to check for examples like: 'Boston (Mass.) Police Dept.'
    def self.corpNamePartSplitter(inputstring)
      splitNamePartsArray = Array.new
      unless inputstring =~ /[\S]{5}\.(?!\))/
        splitNamePartsArray << inputstring
      else
        while inputstring =~ /[\S]{5}\.(?!\))/
          snip = /[\S]{5}\.(?!\))/.match(inputstring).post_match
          subpart = inputstring.gsub(snip,"")
          splitNamePartsArray << subpart.gsub(/\.\z/,"").strip
          inputstring = snip
        end
        splitNamePartsArray << inputstring.gsub(/\.\z/,"").strip
      end
      return splitNamePartsArray
    end

    def self.strip_value(value)
      if(value.blank?)
        return nil
      else
        if value.class == Float || value.class == Integer
          value = value.to_i.to_s
        end

        # Make sure it is all UTF-8 and not character encodings or HTML tags and remove any cariage returns
        return utf8Encode(value)
      end
    end

    def self.utf8Encode(value)
      value = value.force_encoding('UTF-8')
      value.encode!("UTF-8", 'binary', invalid: :replace, undef: :replace, replace: '') unless value.valid_encoding?
      return ::HTMLEntities.new.decode(ActionView::Base.full_sanitizer.sanitize(value.to_s.gsub(/\r?\n?\t/, ' ').gsub(/\r?\n/, ' ').gsub(/<br[\s]*\/>/,' '))).gsub("\\'", "'").strip
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

    # return an array:
    # [nonSort leading article (with spaces), remaining title]
    def self.getProperTitle(title)
      non_sort = nil
      title_array = title.split(' ')
      spec_char_regex = /\A[\S]{1,2}['-]/
      string_to_eval = if title_array[0].match?(spec_char_regex)
                         title_array[0].match(spec_char_regex)[0]
                       else
                         title_array[0]
                       end
      if Bplmodels::Constants::NONSORT_ARTICLES.include?(string_to_eval.downcase)
        non_sort = string_to_eval
      end
      title_minus_sort = title.sub(/#{non_sort}/, '')
      non_sort += ' ' if title_minus_sort.first.match?(/\A\s/)
      [non_sort, title_minus_sort.lstrip]
    end

    def self.parse_language(language_value)
      return_hash = {}
      authority_check = Qa::Authorities::Loc.subauthority_for('iso639-2')
      authority_result = authority_check.search(CGI.escape(language_value))

      if authority_result.present?
        authority_result = authority_result.select{|hash| hash['label'].downcase == language_value.downcase || hash['id'].split('/').last.downcase == language_value.downcase }
        if  authority_result.present?
          return_hash[:uri] = authority_result.first["id"].gsub('info:lc', 'http://id.loc.gov')
          return_hash[:label] = authority_result.first["label"]
        end
      end

      return return_hash
    end

    def self.parse_role(role_value)
      return_hash = {}
      authority_check = Qa::Authorities::Loc.subauthority_for('relators')
      authority_result = authority_check.search(CGI.escape(role_value))
      if authority_result.present?
        authority_result = authority_result.select{|hash| hash['label'].downcase == role_value.downcase}
        if  authority_result.present?
          return_hash[:uri] = authority_result.first["id"].gsub('info:lc', 'http://id.loc.gov')
          return_hash[:label] = authority_result.first["label"]
        end
      end

      return return_hash
    end

    def self.parse_name_roles(name)
      return_hash = {}

      #Make sure we have at least three distinct parts of 2-letter+ words. Avoid something like: Steven C. Painter or Painter, Steven C.
      #Possible Issue: Full name of Steven Carlos Painter ?
      potential_role_check = name.match(/[\(\"\',]*\w\w+[\),\"\']* [\w\.,\d\-\"]*[\w\d][\w\d][\w\.,\d\-\"]* [\(\"\',]*\w\w+[\),\"\']*$/) || name.split(/[ ]+/).length >= 4

      if potential_role_check.present?
        authority_check = Qa::Authorities::Loc.subauthority_for('relators')

        #Check the last value of the name string...
        role_value = name.match(/(?<=[\(\"\', ])\w+(?=[\),\"\']*$)/).to_s
        authority_result = authority_check.search(CGI.escape(role_value))
        if authority_result.present?

          authority_result = authority_result.select{|hash| hash['label'].downcase == role_value.downcase}
          if  authority_result.present?
            #Remove the word and any other characters around it. $ means the end of the line.
            #
            return_hash[:name] = name.sub(/[\(\"\', ]*\w+[\),\"\']*$/, '').gsub(/^[ ]*:/, '').strip
            return_hash[:uri] = authority_result.first["id"].gsub('info:lc', 'http://id.loc.gov')
            return_hash[:label] = authority_result.first["label"]
          end
        end

        #Check the last value of the name string...
        role_value = name.match(/\w+(?=[\),\"\']*)/).to_s
        authority_result = authority_check.search(CGI.escape(role_value))
        if authority_result.present? && return_hash.blank?

          authority_result = authority_result.select{|hash| hash['label'].downcase == role_value.downcase}
          if  authority_result.present?
            #Remove the word and any other characters around it. $ means the end of the line.
            return_hash[:name] = name.sub(/[\(\"\', ]*\w+[ \),\"\']*/, '').gsub(/^[ ]*:/, '').strip
            return_hash[:uri] = authority_result.first["id"].gsub('info:lc', 'http://id.loc.gov')
            return_hash[:label] = authority_result.first["label"]
          end
        end
      end

      return return_hash
    end

    def self.is_numeric? (string)
      true if Float(string) rescue false
    end

    # returns a well-formatted placename for display on a map
    # hiergeo_hash = hash of <mods:hierarchicahlGeographic> elements
    def self.render_display_placename(hiergeo_hash)
      placename = []
      case hiergeo_hash[:country]
        when 'United States','Canada'
          if hiergeo_hash[:state] || hiergeo_hash[:province]
            placename[0] = hiergeo_hash[:other].presence || hiergeo_hash[:city_section].presence || hiergeo_hash[:city].presence || hiergeo_hash[:island].presence || hiergeo_hash[:area].presence
            if placename[0].nil? && hiergeo_hash[:county]
              placename[0] = hiergeo_hash[:county] + ' (county)'
            end
            if placename[0]
              placename[1] = Constants::STATE_ABBR.key(hiergeo_hash[:state]) || hiergeo_hash[:province].presence
            else
              placename[1] = hiergeo_hash[:state].presence || hiergeo_hash[:province].presence
            end
          else
            placename[0] = hiergeo_hash[:other].presence || hiergeo_hash[:city_section].presence || hiergeo_hash[:city].presence || hiergeo_hash[:island].presence || hiergeo_hash[:area].presence || hiergeo_hash[:region].presence || hiergeo_hash[:territory].presence || hiergeo_hash[:country].presence
          end
        else
          placename[0] = hiergeo_hash[:other].presence || hiergeo_hash[:city_section].presence || hiergeo_hash[:city].presence || hiergeo_hash[:island].presence || hiergeo_hash[:area].presence || hiergeo_hash[:state].presence || hiergeo_hash[:province].presence || hiergeo_hash[:region].presence || hiergeo_hash[:territory].presence
          if placename[0].nil? && hiergeo_hash[:county]
            placename[0] = hiergeo_hash[:county] + ' (county)'
          end
          placename[1] = hiergeo_hash[:country]
      end

      if !placename.blank?
        placename.join(', ').gsub(/(\A,\s)|(,\s\z)/,'')
      else
        nil
      end
    end

    def self.get_fits_xml(datastream)
      return unless datastream.has_content?
      Hydra::FileCharacterization.characterize(datastream.content, datastream.filename_for_characterization.join(""), :fits) do |config|
        config[:fits] = ENV.fetch("FITS_PATH", "#{ENV['HOME']}/tools/Fits/fits.sh")
      end
    end

  end
end
