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
  end
end
