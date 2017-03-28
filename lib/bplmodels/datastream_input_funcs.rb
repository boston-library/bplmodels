#!/bin/env ruby
# encoding: utf-8
require 'htmlentities'

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
          splitNamePartsHash[:datePart] = splitArray[1].strip
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
        if value.class == Float || value.class == Fixnum
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

    #Problems: A . Some Name and A & R
    def self.getProperTitle(title)
      nonSort = nil
      title = title

      if title[0..1].downcase == "a " && (title[0..2].downcase != "a ." && title[0..2].downcase != "a &")
        nonSort = title[0..1]
        title = title[2..title.length]
      elsif title[0..3].downcase == "the "
        nonSort = title[0..3]
        title = title[4..title.length]
      elsif title[0..2].downcase == "an "
        nonSort = title[0..2]
        title = title[3..title.length]
        #elsif title[0..6].downcase == "in the "
        #return [title[0..5], title[7..title.length]]
      end

      return [nonSort, title]
    end

    def self.parse_language(language_value)
      return_hash = {}
      authority_check = Qa::Authorities::Loc.new
      authority_result = authority_check.search(URI.escape(language_value), 'iso639-2')

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
      authority_check = Qa::Authorities::Loc.new
      authority_result = authority_check.search(URI.escape(role_value), 'relators')
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
        authority_check = Qa::Authorities::Loc.new

        #Check the last value of the name string...
        role_value = name.match(/(?<=[\(\"\', ])\w+(?=[\),\"\']*$)/).to_s
        authority_result = authority_check.search(URI.escape(role_value), 'relators')
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
        authority_result = authority_check.search(URI.escape(role_value), 'relators')
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

  end
end
