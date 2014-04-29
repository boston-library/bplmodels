#encoding: utf-8
require 'mods'

module Bplmodels
  class ModsDescMetadata < ActiveFedora::OmDatastream
    #include Hydra::Datastream::CommonModsIndexMethods
    # MODS XML constants.

    def self.default_attributes
      super.merge(:mimeType => 'application/xml')
    end

    MODS_NS = 'http://www.loc.gov/mods/v3'
    MODS_SCHEMA = 'http://www.loc.gov/standards/mods/v3/mods-3-4.xsd'
    MODS_PARAMS = {
        "version"            => "3.4",
        "xmlns:xlink"        => "http://www.w3.org/1999/xlink",
        "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
        #"xmlns"              => MODS_NS,
        "xsi:schemaLocation" => "#{MODS_NS} #{MODS_SCHEMA}",
        "xmlns:mods"         => "http://www.loc.gov/mods/v3"
    }

    # OM terminology.

    set_terminology do |t|
      indexer = Solrizer::Descriptor.new(:string, :indexed, :stored, :searchable)
      indexer_single = Solrizer::Descriptor.new(:text, :indexed, :stored, :searchable)
      indexer_multiple = Solrizer::Descriptor.new(:text, :indexed, :stored, :searchable, :multivalued)

      t.root :path => 'mods', :xmlns => MODS_NS
      t.originInfo  do
        t.dateOther
      end
      #t.abstract(:path=>"abstract", :index_as=>[indexer_single])

      # ABSTRACT -------------------------------------------------------------------------------
      #t.abstract(:path=>"mods/oxns:abstract") {
      t.abstract(:path=>"abstract") {
        t.displayLabel :path=>{:attribute=>'displayLabel'}
        t.type_at :path=>{:attribute=>"type"}
        ::Mods::LANG_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
      }

      # GENRE ----------------------------------------------------------------------------------
      t.genre(:path => 'genre') {
        t.displayLabel :path => {:attribute=>'displayLabel'}
        t.type_at :path=>{:attribute=>"type"}
        t.usage :path=>{:attribute=>'usage'}
        ::Mods::AUTHORITY_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
        ::Mods::LANG_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
      }

      # IDENTIIER ------------------------------------------------------------------------------
      t.identifier(:path => 'identifier') {
      #t.identifier(:path=>"identifier[not(@type=uri)]")
        t.displayLabel :path=>{:attribute=>'displayLabel'}
        t.invalid :path=>{:attribute=>'invalid'}
        t.type_at :path=>{:attribute=>'type'}
        ::Mods::LANG_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
      }

=begin
      # ACCESS_CONDITION -----------------------------------------------------------------------
      t.accessCondition(:path => 'mods/oxns:accessCondition') {
        t.displayLabel :path=>{:attribute=>'displayLabel'}
        t.type_at :path=>{:attribute=>"type"}
        ::Mods::LANG_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
      }

      # CLASSIFICATION -------------------------------------------------------------------------
      t.classification(:path => 'mods/oxns:classification') {
        t.displayLabel :path=>{:attribute=>'displayLabel'}
        t.edition :path =>{:attribute=>"edition"}
        ::Mods::AUTHORITY_ATTRIBS.each { |attr_name|
          t.send attr_name, :path => {:attribute=>"#{attr_name}"}
        }
        ::Mods::LANG_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
      }


      # EXTENSION ------------------------------------------------------------------------------
      t.extension(:path => 'mods/oxns:extension') {
        t.displayLabel :path=>{:attribute=>'displayLabel'}
      }

      # LANGUAGE -------------------------------------------------------------------------------
      t.language(:path => 'mods/oxns:language') {
        # attributes
        t.displayLabel :path=>{:attribute=>'displayLabel'}
        ::Mods::LANG_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
        # child elements
        t.languageTerm :path => 'languageTerm'
        t.code_term :path => 'languageTerm', :attributes => { :type => "code" }
        t.text_term :path => 'languageTerm', :attributes => { :type => "text" }
        t.scriptTerm :path => 'scriptTerm'
      }
      t.languageTerm(:path => 'languageTerm') {
        t.type_at :path=>{:attribute=>'type'}
        ::Mods::AUTHORITY_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
      } # t.language

      # LOCATION -------------------------------------------------------------------------------
      t.location(:path => 'mods/oxns:location') {
        # attributes
        t.displayLabel :path=>{:attribute=>'displayLabel'}
        ::Mods::LANG_ATTRIBS.each { |attr_name|
          t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
        }
        # child elements
        t.physicalLocation(:path => 'physicalLocation') {
          t.displayLabel :path=>{:attribute=>'displayLabel'}
          ::Mods::AUTHORITY_ATTRIBS.each { |attr_name|
            t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
          }
        }
        t.shelfLocator :path => 'shelfLocator'
        t.url(:path => 'url') {
          t.dateLastAccessed :path=>{:attribute=>'dateLastAccessed'}
          t.displayLabel :path=>{:attribute=>'displayLabel'}
          t.note :path=>{:attribute=>'note'}
          t.access :path=>{:attribute=>'access'}
          t.usage :path=>{:attribute=>'usage'}
        }
        t.holdingSimple :path => 'holdingSimple'
        t.holdingExternal :path => 'holdingExternal'
      } # t.location

      :path => 'languageTerm', :attributes => { :type => "text" }
      # NAME ------------------------------------------------------------------------------------
      t.plain_name(:path => 'mods/oxns:name') {
        ::Mods::Name::ATTRIBUTES.each { |attr_name|
          if attr_name != 'type'
            t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
          else
            t.type_at :path =>{:attribute=>"#{attr_name}"}
          end
        }
        # elements
        t.namePart(:path => 'namePart') {
          t.type_at :path =>{:attribute=>"type"}
        }
        t.family_name :path => 'namePart', :attributes => {:type=>"family"}
        t.given_name :path => 'namePart', :attributes => {:type=>"given"}
        t.termsOfAddress :path => 'namePart', :attributes => {:type=>"termsOfAddress"}
        t.date :path => 'namePart', :attributes => {:type=>"date"}

        t.displayForm :path => 'displayForm'
        t.affiliation :path => 'affiliation'
        t.description_el :path => 'description' # description is used by Nokogiri
        t.role(:path => 'role') {
          t.roleTerm(:path => 'roleTerm') {
            t.type_at :path =>{:attribute=> "type"}
            ::Mods::AUTHORITY_ATTRIBS.each { |attr_name|
              t.send attr_name, :path =>{:attribute=>"#{attr_name}"}
            }
          }
          # FIXME - not sure how to do this stuff
          # role convenience method
          t.authority :path => '.', :accessor => lambda { |role_node|
            a = nil
            role_node.roleTerm.each { |role_t|
              # role_t.authority will be [] if it is missing from an earlier roleTerm
              if role_t.authority && (!a || a.size == 0)
                a = role_t.authority
              end
            }
            a
          }
          # role convenience method
          r.code :path => '.', :accessor => lambda { |role_node|
            c = nil
            role_node.roleTerm.each { |role_t|
              if role_t.type_at == 'code'
                c ||= role_t.text
              end
            }
            c
          }
          # role convenience method
          r.value :path => '.', :accessor => lambda { |role_node|
            val = nil
            role_node.roleTerm.each { |role_t|
              if role_t.type_at == 'text'
                val ||= role_t.text
              end
            }
            # FIXME: this is broken if there are multiple role codes and some of them are not marcrelator
            if !val && role_node.code && role_node.authority.first =~ /marcrelator/
              val = MARC_RELATOR[role_node.code.first]
            end
            val
          }
        } # role node
        #END FIXME

        # name convenience method
        # uses the displayForm of a name if present
        # if no displayForm, try to make a string from family, given and terms of address
        # otherwise, return all non-date nameParts concatenated together
        n.display_value :path => '.', :single => true, :accessor => lambda {|name_node|
          dv = ''
          if name_node.displayForm && name_node.displayForm.text.size > 0
            dv = name_node.displayForm.text
          end
          if dv.blank?
            if name_node.type_at == 'personal'
              if name_node.family_name.size > 0
                dv = name_node.given_name.size > 0 ? "#{name_node.family_name.text}, #{name_node.given_name.text}" : name_node.family_name.text
              elsif name_node.given_name.size > 0
                dv = name_node.given_name.text
              end
              if !dv.blank?
                first = true
                name_node.namePart.each { |np|
                  if np.type_at == 'termsOfAddress' && !np.text.blank?
                    if first
                      dv = dv + " " + np.text
                      first = false
                    else
                      dv = dv + ", " + np.text
                    end
                  end
                }
              else # no family or given name
                dv = name_node.namePart.select {|np| np.type_at != 'date' && !np.text.blank?}.join(" ")
              end
            else # not a personal name
              dv = name_node.namePart.select {|np| np.type_at != 'date' && !np.text.blank?}.join(" ")
            end
          end
          dv.strip.blank? ? nil : dv.strip
        }

        # name convenience method
        n.display_value_w_date :path => '.', :single => true, :accessor => lambda {|name_node|
          dv = ''
          dv = dv + name_node.display_value if name_node.display_value
          name_node.namePart.each { |np|
            if np.type_at == 'date' && !np.text.blank? && !dv.end_with?(np.text)
              dv = dv + ", #{np.text}"
            end
          }
          if dv.start_with?(', ')
            dv.sub(', ', '')
          end
          dv.strip.blank? ? nil : dv.strip
        }
      } # t._plain_name

      t.personal_name :path => '/m:mods/m:name[@type="personal"]'
      t._personal_name :path => '//m:name[@type="personal"]'
      t.corporate_name :path => '/m:mods/m:name[@type="corporate"]'
      t._corporate_name :path => '//m:name[@type="corporate"]'
      t.conference_name :path => '/m:mods/m:name[@type="conference"]'
      t._conference_name :path => '//m:name[@type="conference"]'
=end






      t.title_info(:path=>'titleInfo') {
        t.usage(:path=>{:attribute=>"usage"})
        t.nonSort(:path=>"nonSort", :index_as=>[:searchable, :displayable])
        t.main_title(:path=>"title", :label=>"title")
        t.language(:index_as=>[:facetable],:path=>{:attribute=>"lang"})
        t.supplied(:path=>{:attribute=>"supplied"})
        t.type(:path=>{:attribute=>"type"})
        t.authority(:path=>{:attribute=>"authority"})
        t.authorityURI(:path=>{:attribute=>"authorityURI"})
        t.valueURI(:path=>{:attribute=>"valueURI"})
        t.subtitle(:path=>"subtitle", :label=>"subtitle")
      }
      t.title(:proxy=>[:title_info, :main_title])

      t.name(:path=>'name') {
        # this is a namepart
        t.usage(:path=>{:attribute=>"usage"})
        t.namePart(:type=>:string, :label=>"generic name")
        t.type(:path=>{:attribute=>"type"})
        t.authority(:path=>{:attribute=>"authority"})
        t.authorityURI(:path=>{:attribute=>"authorityURI"})
        t.valueURI(:path=>{:attribute=>"valueURI"})

        t.role(:ref=>[:role])
        t.date(:path=>"namePart", :attributes=>{:type=>"date"})
      }

      t.type_of_resource(:path=>"typeOfResource")  {
        t.manuscript(:path=>{:attribute=>"manuscript"})
      }


      t.genre_basic(:path=>"genre", :attributes=>{:displayLabel => "general"})

      t.genre_specific(:path=>"genre", :attributes=>{:displayLabel => "specific"})

      t.origin_info(:path=>"originInfo") {
        t.publisher(:path=>"publisher")
        t.place(:path=>"place") {
          t.place_term(:path=>"placeTerm", :attributes=>{:type=>'text'})
        }
        t.issuance(:path=>"issuance")
      }

      t.item_location(:path=>"location") {
        t.physical_location(:path=>"physicalLocation")
        t.holding_simple(:path=>"holdingSimple") {
          t.copy_information(:path=>"copyInformation") {
            t.sub_location(:path=>"subLocation")
            t.shelf_locator(:path=>"shelfLocator")
          }
        }
        t.url(:path=>"url") {
          t.usage(:path=>{:attribute=>"usage"})
          t.access(:path=>{:attribute=>"access"})
        }
      }




      t.identifier_accession :path => 'identifier', :attributes => { :type => "accession number" }
      t.identifier_barcode :path => 'identifier', :attributes => { :type => "barcode" }
      t.identifier_bpldc :path => 'identifier', :attributes => { :type => "bpldc number" }
      t.identifier_other :path => 'identifier', :attributes => { :type => "other" }

      t.local_other :path => 'identifier', :attributes => { :type => "local-other" }

      t.local_accession :path => 'identifier', :attributes => { :type => "local-accession" }
      t.local_call :path => 'identifier', :attributes => { :type => "local-call" }
      t.identifier_uri :path => 'identifier', :attributes => { :type => "uri" }

      t.physical_description(:path=>"physicalDescription") {
        t.internet_media_type(:path=>"internetMediaType")
        t.digital_origin(:path=>"digitalOrigin")
        t.extent(:path=>"extent")
        t.note(:path=>'note')
      }

      t.note(:path=>"note") {
        t.type_at(:path=>{:attribute=>"type"})
      }


      t.personal_name(:path=>'mods/oxns:subject/oxns:name', :attributes=>{:type => "personal"}) {
        t.name_part(:path=>"namePart[not(@type)]")
        t.date(:path=>"namePart", :attributes=>{:type=>"date"})
      }

      t.corporate_name(:path=>'mods/oxns:subject/oxns:name', :attributes=>{:type => "corporate"}) {
        t.name_part(:path=>"namePart[not(@type)]")
        t.date(:path=>"namePart", :attributes=>{:type=>"date"})
      }


      t.subject  do
        t.topic
        t.geographic
        t.authority(:path=>{:attribute=>"authority"})
        t.valueURI(:path=>{:attribute=>"valueURI"})
        t.authorityURI(:path=>{:attribute=>"authorityURI"})
        t.personal_name(:path=>'name', :attributes=>{:type => "personal"}) {
          t.name_part(:path=>"namePart[not(@type)]")
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
        }
        t.corporate_name(:path=>'name', :attributes=>{:type => "corporate"}) {
          t.name_part(:path=>"namePart[not(@type)]")
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
        }
        t.conference_name(:path=>'name', :attributes=>{:type => "conference"}) {
          t.name_part(:path=>"namePart[not(@type)]")
        }
        t.name(:path=>'name') {
          t.name_part(:path=>"namePart[not(@type)]")
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
          t.name_part_actual(:path=>"namePart") {
            t.type(:path=>{:attribute=>"type"})
          }
          t.type(:path=>{:attribute=>"type"})
          t.authority(:path=>{:attribute=>"authority"})
          t.authority_uri(:path=>{:attribute=>"authorityURI"})
          t.value_uri(:path=>{:attribute=>"valueURI"})
        }
        t.hierarchical_geographic(:path=>"hierarchicalGeographic") {
          t.continent
          t.country
          t.province
          t.region
          t.state
          t.territory
          t.county
          t.city
          t.city_section(:path=>"citySection")
          t.island
          t.area
          t.extarea(:path=>"extraterrestrialArea")
        }
        t.cartographics {
          t.coordinates
          t.scale
          t.projection
        }
        t.temporal(:path=>'temporal', :attributes=>{:encoding => "w3cdtf"}) {
          t.point(:path=>{:attribute=>"point"})
        }

      end


      t.related_item(:path=>"relatedItem") {
        t.type(:path=>{:attribute=>"type"})
        t.href(:path=>{:attribute=>'xlink:href'})
        t.title_info(:path=>"titleInfo") {
          t.title
          t.nonSort(:path=>"nonSort")
        }
        t.identifier
        t.location(:path=>'location') {
          t.url(:path=>'url')
        }
        t.related_item(:ref=>[:related_series_item]) {
          t.related_item(:ref=>[:related_series_item]) {
            t.related_item(:ref=>[:related_series_item]) {
              t.related_item(:ref=>[:related_series_item])
            }
          }
        }
        t.subseries(:path=>'relatedItem', :attributes=>{:type => "series"}) {
          t.title_info(:path=>"titleInfo") {
            t.title
            t.nonSort(:path=>"nonSort")
          }
          t.subsubseries(:path=>'relatedItem', :attributes=>{:type => "series"}) {
            t.title_info(:path=>"titleInfo") {
              t.title
              t.nonSort(:path=>"nonSort")
            }
          }
        }

      }

      t.related_series_item(:path=>'relatedItem') {
        t.type(:path=>{:attribute=>"type"})
        t.title_info(:path=>"titleInfo") {
          t.title
          t.nonSort(:path=>"nonSort")
        }
      }


      #t.subseries(:path=>'mods/oxns:relatedItem/oxns:relatedItem', :attributes=>{:type => "series"}) {
      #  t.title_info(:path=>"titleInfo") {
      #    t.title
      #    t.nonSort(:path=>"nonSort")
      #  }
      #}

      t.use_and_reproduction(:path=>"accessCondition", :attributes=>{:type=>"use and reproduction"})

      t.restriction_on_access(:path=>"accessCondition", :attributes=>{:type=>"restrictions on access"})



      t.date(:path=>"originInfo") {
        t.date_other(:path=>"dateOther") {
          t.encoding(:path=>{:attribute=>"encoding"})
          t.key_date(:path=>{:attribute=>"keyDate"})
          t.type(:path=>{:attribute=>"type"})
          t.qualifier(:path=>{:attribute=>"qualifier"})
        }
        t.dates_created(:path=>"dateCreated") {
          t.encoding(:path=>{:attribute=>"encoding"})
          t.key_date(:path=>{:attribute=>"keyDate"})
          t.point(:path=>{:attribute=>"point"})
          t.qualifier(:path=>{:attribute=>"qualifier"})
        }
        t.dates_issued(:path=>"dateIssued") {
          t.encoding(:path=>{:attribute=>"encoding"})
          t.key_date(:path=>{:attribute=>"keyDate"})
          t.point(:path=>{:attribute=>"point"})
          t.qualifier(:path=>{:attribute=>"qualifier"})
        }
        t.dates_copyright(:path=>"copyrightDate") {
          t.encoding(:path=>{:attribute=>"encoding"})
          t.key_date(:path=>{:attribute=>"keyDate"})
          t.point(:path=>{:attribute=>"point"})
          t.qualifier(:path=>{:attribute=>"qualifier"})
        }

      }

      t.role {
        t.text(:path=>'roleTerm',:attributes=>{:type=>'text', :authority=>'marcrelator', :authorityURI=>'http://id.loc.gov/vocabulary/relators'}) {
          t.valueURI(:path=>{:attribute=>'valueURI'})
        }
        t.code(:path=>'roleTerm',:attributes=>{:type=>'code'})
      }

      t.language(:path=>"language") {
        t.language_term(:path=>"languageTerm") {
          t.lang_val_uri(:path=>{:attribute=>"valueURI"})
        }
      }

      t.record_info(:path=>'recordInfo') {
        t.description_standard(:path=>'descriptionStandard', :attributes=>{:authority=>"marcdescription"})
        t.record_content_source(:path=>'recordContentSource') {
          t.authority(:path=>{:attribute=>"authority"})
        }
        t.record_origin(:path=>'recordOrigin')
        t.language_of_cataloging(:path=>'languageOfCataloging') {
          t.language_term(:path=>'languageTerm', :attributes => { :authority => 'iso639-2b',:authorityURI=> 'http://id.loc.gov/vocabulary/iso639-2', :type=>'text', :valueURI=>'http://id.loc.gov/vocabulary/iso639-2/eng'  })
        }
      }


      t.table_of_contents(:path=>'tableOfContents')


    end

    # Blocks to pass into Nokogiri::XML::Builder.new()
=begin
    define_template :name do |xml|
      xml.name {
        xml.namePart
        xml.role {
          xml.roleTerm(:authority => "marcrelator", :type => "text")
        }
      }
    end

    define_template :relatedItem do |xml|
      xml.relatedItem {
        xml.titleInfo {
          xml.title
        }
        xml.location {
          xml.url
        }
      }
    end

    define_template :related_citation do |xml|
      xml.note(:type => "citation/reference")
    end
=end

    def self.xml_template
      builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
        xml.mods(MODS_PARAMS) {
          xml.parent.namespace = xml.parent.namespace_definitions.find{|ns|ns.prefix=="mods"}

        }
      end
      return builder.doc
    end

    #def insert_physical_description(media_type=nil, digital_origin=nil, media_type2=nil, note=nil)

    def insert_digital_origin(digital_origin=nil)
      physical_description_index = 0
      origin_index = self.mods(0).physical_description(physical_description_index).digital_origin.count
      self.mods(0).physical_description(physical_description_index).digital_origin(origin_index, digital_origin) unless digital_origin.blank?
    end

    def insert_physical_note(note=nil)
      physical_description_index = 0
      note_index = self.mods(0).physical_description(physical_description_index).note.count
      self.mods(0).physical_description(physical_description_index).note(note_index, note) unless note.blank?
    end

    def remove_physical_description(index)
      self.find_by_terms(:physical_description).slice(index.to_i).remove
    end

    def insert_media_type(media_type=nil)
      physical_description_index = 0
      media_type_index = self.mods(0).physical_description(physical_description_index).internet_media_type.count
      self.mods(0).physical_description(physical_description_index).internet_media_type(media_type_index, media_type) unless media_type.blank? ||  self.mods(0).physical_description(physical_description_index).internet_media_type.include?(media_type)
    end



    define_template :language do |xml, value, code|
      xml.language {
        xml.languageTerm(:type=>"text", :authority=>"iso639-2b", :authorityURI=>"http://id.loc.gov/vocabulary/iso639-2", :valueURI=>code) {
          xml.text value
        }
      }
    end

    def insert_language(value=nil, code='eng')
      code = "http://id.loc.gov/vocabulary/iso639-2/#{code}" unless code.include?('http')
      add_child_node(ng_xml.root, :language, value, code)
    end

    def remove_language(index)
      self.find_by_terms(:language).slice(index.to_i).remove
    end

    define_template :rights do |xml, value, type|
      xml.accessCondition(:type=>type) {
        xml.text value
      }
    end

    def insert_rights(value=nil, type=nil)
      add_child_node(ng_xml.root, :rights, value, type)
    end

    def remove_rights(index)
      self.find_by_terms(:rights).slice(index.to_i).remove
    end


    def insert_type_of_resource(value=nil, manuscript=nil)
      resource_index = self.mods(0).type_of_resource.count

      self.mods(0).type_of_resource(resource_index, value) unless value.blank? || self.mods(0).type_of_resource.include?(value)
      self.mods(0).type_of_resource(resource_index).manuscript = 'yes' unless manuscript.blank? || self.mods(0).type_of_resource.include?(value)
    end

    def remove_type_of_resource(index)
      self.find_by_terms(:type_of_resource).slice(index.to_i).remove
    end

    def insert_publisher(publisher=nil, place=nil)
      origin_index = 0
      publisher_index = self.mods(0).origin_info(origin_index).publisher.count
      place_index =  self.mods(0).origin_info(origin_index).place.count

      self.mods(0).origin_info(origin_index).publisher(publisher_index, publisher) unless publisher.blank?
      self.mods(0).origin_info(origin_index).place(place_index).place_term = place unless place.blank?
    end

    def remove_publisher(index)
      self.find_by_terms(:mods, :publisher).slice(index.to_i).remove
    end

    def insert_issuance(issuance=nil)
      origin_index = 0
      issuance_index = self.mods(0).origin_info(origin_index).issuance.count

      self.mods(0).origin_info(origin_index).issuance(issuance_index, issuance) unless issuance.blank?
    end


    def insert_genre(value=nil, value_uri=nil, authority=nil, display_label='specific')
      genre_index = self.mods(0).genre.count

      self.mods(0).genre(genre_index, value) unless value.blank?

      self.mods(0).genre(genre_index).authority = authority unless authority.blank?

      if authority == 'gmgpc' || authority == 'lctgm'
        self.mods(0).genre(genre_index).authorityURI = 'http://id.loc.gov/vocabulary/graphicMaterials'
      end

      self.mods(0).genre(genre_index).valueURI = value_uri unless value_uri.blank?

      self.mods(0).genre(genre_index).displayLabel = display_label unless display_label.blank?

    end

    def remove_genre(index)
      self.find_by_terms(:genre).slice(index.to_i).remove
    end

    define_template :access_links do |xml, preview, primary|
      xml.location {
        if preview != nil && preview.length > 0
          xml.url(:access=>"preview") {
            xml.text preview
          }
        end
        xml.url(:usage=>"primary", :access=>"object in context") {
          xml.text primary
        }
      }
    end

    def insert_access_links(preview=nil, primary=nil)
      add_child_node(ng_xml.root, :access_links, preview, primary)
    end

    def remove_access_links(index)
      self.find_by_terms(:access_links).slice(index.to_i).remove
    end

    def insert_tgn(tgn_id)
      puts 'TGN ID is: ' + tgn_id

      #Duplicate TGN value?
      if self.subject.valueURI.include?(tgn_id)
        return false
      end

      api_result = Bplgeo::TGN.get_tgn_data(tgn_id)

      puts 'API Result is: ' + api_result.to_s

      #Get rid of less specific matches... city level information should trump state level information.
      if api_result[:hier_geo][:city].present? && self.subject.hierarchical_geographic.present?
        self.mods(0).subject.each_with_index do |ignored, subject_index|
          if self.mods(0).subject(subject_index).authority == ['tgn']
            if self.mods(0).subject(subject_index).hierarchical_geographic(0).city.blank? && self.mods(0).subject(subject_index).hierarchical_geographic(0).state == [api_result[:hier_geo][:state]]
              self.mods(0).subject(subject_index, nil)
            end
          end
        end

        #Exit if same city match
        self.mods(0).subject.each_with_index do |ignored, subject_index|
          if self.mods(0).subject(subject_index).authority == ['tgn']
            if self.mods(0).subject(subject_index).hierarchical_geographic(0).city == [api_result[:hier_geo][:city]]
              return false
            end
          end
        end
      #Exit check if trying to insert same state twice with no city
      elsif api_result[:hier_geo][:city].blank? && api_result[:hier_geo][:state].present? && self.subject.hierarchical_geographic.present?
        self.mods(0).subject.each_with_index do |ignored, subject_index|
          if self.mods(0).subject(subject_index).authority == ['tgn']
            if self.mods(0).subject(subject_index).hierarchical_geographic(0).state == [api_result[:hier_geo][:state]]
              return false
            end
          end
        end
      #Finally exit if inserting the same country...
      elsif api_result[:hier_geo][:city].blank? && api_result[:hier_geo][:state].blank? && api_result[:hier_geo][:country].present? && self.subject.hierarchical_geographic.present?
        self.mods(0).subject.each_with_index do |ignored, subject_index|
          if self.mods(0).subject(subject_index).authority == ['tgn']
            if self.mods(0).subject(subject_index).hierarchical_geographic(0).country == [api_result[:hier_geo][:country]]
              return false
            end
          end
        end
      end

      subject_index = self.mods(0).subject.count

      self.mods(0).subject(subject_index).authority = "tgn"
      self.mods(0).subject(subject_index).valueURI = tgn_id

      #Insert geographic text
      if api_result[:non_hier_geo] != nil
        self.mods(0).subject(subject_index).geographic = api_result[:non_hier_geo]
      end

      #Insert hierarchicalGeographic text
      if api_result[:hier_geo] != nil
        api_result[:hier_geo].keys.reverse.each do |key|
          key_with_equal = key.to_s + "="
          self.mods(0).subject(subject_index).hierarchical_geographic.send(key_with_equal.to_sym, Bplmodels::DatastreamInputFuncs.utf8Encode(api_result[:hier_geo][key]))
        end
      end

      #Insert Coordinates
      if api_result[:coords] != nil
        self.mods(0).subject(subject_index).cartographics.coordinates = api_result[:coords][:latitude] + "," + api_result[:coords][:longitude]
      end
    end

    #usage=nil,  supplied=nil, subtitle=nil, language=nil, type=nil, authority=nil, authorityURI=nil, valueURI=nil
    def insert_title(nonSort=nil, main_title=nil, usage=nil, supplied=nil, type=nil, args={})
      puts args
      title_index = self.mods(0).title_info.count
      self.mods(0).title_info(title_index).nonSort = nonSort unless nonSort.blank?
      self.mods(0).title_info(title_index).main_title = main_title unless main_title.blank?

      self.mods(0).title_info(title_index).usage = usage unless usage.blank?
      self.mods(0).title_info(title_index).supplied = 'yes' unless supplied.blank? || supplied == 'no'

      self.mods(0).title_info(title_index).type = type unless type.blank?

      args.each do |key, value|
        self.mods(0).title_info(title_index).send(key, Bplmodels::DatastreamInputFuncs.utf8Encode(value)) unless value.blank?
      end
    end

    def remove_title(index)
      self.find_by_terms(:mods, :title_info).slice(index.to_i).remove
    end

    #image.descMetadata.find_by_terms(:name).slice(0).set_attribute("new", "true")


    def insert_name(name=nil, type=nil, authority=nil, value_uri=nil, role=nil, role_uri=nil, args={})
      puts name
      puts role
      puts role_uri

      name_index = self.mods(0).name.count
      self.mods(0).name(name_index).type = type unless type.blank?
      self.mods(0).name(name_index).authority = authority unless authority.blank?
      self.mods(0).name(name_index).valueURI = value_uri unless value_uri.blank?

      if role.present?
        self.mods(0).name(name_index).role.text = role unless role.blank?
        self.mods(0).name(name_index).role.text.valueURI = role_uri unless role_uri.blank?
      end

      if(authority == 'naf')
        self.mods(0).name(name_index).authorityURI = 'http://id.loc.gov/authorities/names'
      end

      if type == 'corporate'
        name_array = Bplmodels::DatastreamInputFuncs.corpNamePartSplitter(name)
        name_array.each_with_index do |name_value, array_pos|
          self.mods(0).name(name_index).namePart(array_pos, name_value)
        end
      elsif type=='personal'
        name_hash = Bplmodels::DatastreamInputFuncs.persNamePartSplitter(name)
        self.mods(0).name(name_index).namePart = name_hash[:namePart]
        self.mods(0).name(name_index).date = name_hash[:datePart] unless name_hash[:datePart].blank?
      else
        self.mods(0).name(name_index).namePart = name
      end
      args.each do |key, value|
        self.mods(0).name(name_index).send(key, Bplmodels::DatastreamInputFuncs.utf8Encode(value)) unless value.blank?
      end
    end


    def remove_name(index)
      self.find_by_terms(:mods, :name).slice(index.to_i).remove
    end

    #test = ["test1", "test2"]
    #test.each do |k|
    #define_method "current_#{k.underscore}" do
    #puts k.underscore
    #end
    #end

    def insert_oai_date(date)
      converted = Bplmodels::DatastreamInputFuncs.convert_to_mods_date(date)

      #date_index =  self.date.length
      date_index = 0
      dup_found = false

      #Prevent duplicate entries... Using a flag as keep the potential note?
      (self.mods(0).date(date_index).dates_created.length-1).times do |index|
        if converted.has_key?(:single_date)
          if self.mods(0).date(date_index).dates_created(index).point.blank? && self.mods(0).date(date_index).dates_created(index).first == converted[:single_date]
            dup_found = true
          end
        elsif converted.has_key?(:date_range)
          if self.mods(0).date(date_index).dates_created(index).point == 'start' && self.mods(0).date(date_index).dates_created(index).first == converted[:date_range][:start]
            if self.mods(0).date(date_index).dates_created(index+1).point == 'end' && self.mods(0).date(date_index).dates_created(index+1).first == converted[:date_range][:end]
              dup_found = true
            end

          end
        end
      end

      if !dup_found
        if converted.has_key?(:single_date) && !self.date.dates_created.include?(converted[:single_date])
          date_created_index = self.date(date_index).dates_created.length
          self.date(date_index).dates_created(date_created_index, converted[:single_date])
          self.date(date_index).dates_created(date_created_index).encoding = 'w3cdtf'
          if date_created_index == 0
            self.date(date_index).dates_created(date_created_index).key_date = 'yes'
          end

          if converted.has_key?(:date_qualifier)
            self.date(date_index).dates_created(date_created_index).qualifier =  converted[:date_qualifier]
          end
        elsif converted.has_key?(:date_range)
          date_created_index = self.date(date_index).dates_created.length
          self.date(date_index).dates_created(date_created_index, converted[:date_range][:start])
          self.date(date_index).dates_created(date_created_index).encoding = 'w3cdtf'
          if date_created_index == 0
            self.date(date_index).dates_created(date_created_index).key_date = 'yes'
          end
          self.date(date_index).dates_created(date_created_index).point = 'start'
          self.date(date_index).dates_created(date_created_index).qualifier = converted[:date_qualifier]

          date_created_index = self.date(date_index).dates_created.length
          self.date(date_index).dates_created(date_created_index, converted[:date_range][:end])
          self.date(date_index).dates_created(date_created_index).encoding = 'w3cdtf'
          self.date(date_index).dates_created(date_created_index).point = 'end'
          self.date(date_index).dates_created(date_created_index).qualifier = converted[:date_qualifier]
        end
      end



      self.insert_note(converted[:date_note],"date") unless !converted.has_key?(:date_note)

    end

    def insert_oai_date_issued(date)
      converted = Bplmodels::DatastreamInputFuncs.convert_to_mods_date(date)

      #date_index =  self.date.length
      date_index = 0

      if converted.has_key?(:single_date)
        date_created_index = self.date(date_index).dates_issued.length
        self.date(date_index).dates_issued(date_created_index, converted[:single_date])
        self.date(date_index).dates_issued(date_created_index).encoding = 'w3cdtf'
        if date_created_index == 0
          self.date(date_index).dates_issued(date_created_index).key_date = 'yes'
        end

        if converted.has_key?(:date_qualifier)
          self.date(date_index).dates_issued(date_created_index).qualifier =  converted[:date_qualifier]
        end
      elsif converted.has_key?(:date_range)
        date_created_index = self.date(date_index).dates_issued.length
        self.date(date_index).dates_issued(date_created_index, converted[:date_range][:start])
        self.date(date_index).dates_issued(date_created_index).encoding = 'w3cdtf'
        if date_created_index == 0
          self.date(date_index).dates_issued(date_created_index).key_date = 'yes'
        end
        self.date(date_index).dates_issued(date_created_index).point = 'start'
        self.date(date_index).dates_issued(date_created_index).qualifier = converted[:date_qualifier]

        date_created_index = self.date(date_index).dates_issued.length
        self.date(date_index).dates_issued(date_created_index, converted[:date_range][:end])
        self.date(date_index).dates_issued(date_created_index).encoding = 'w3cdtf'
        self.date(date_index).dates_issued(date_created_index).point = 'end'
        self.date(date_index).dates_issued(date_created_index).qualifier = converted[:date_qualifier]
      end

      self.insert_note(converted[:date_note],"date") unless !converted.has_key?(:date_note)

    end

    define_template :date do |xml, dateStarted, dateEnding, dateQualifier, dateOther|

      if dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.originInfo {
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
          xml.dateCreated(:encoding=>"w3cdtf", :point=>"end", :qualifier=>dateQualifier) {
            xml.text dateEnding
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0
        xml.originInfo {
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start") {
            xml.text dateStarted
          }
          xml.dateCreated(:encoding=>"w3cdtf", :point=>"end") {
            xml.text dateEnding
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.originInfo {
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0
        xml.originInfo {
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes") {
            xml.text dateStarted
          }
        }
      elsif dateOther != nil && dateOther.length > 0
        xml.originInfo {
          xml.dateOther {
            xml.text dateOther
          }
        }
      else
        #puts "error in dates?"

      end
    end

    define_template :date_partial do |xml, dateStarted, dateEnding, dateQualifier, dateOther|

      if dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
          xml.dateCreated(:encoding=>"w3cdtf", :point=>"end", :qualifier=>dateQualifier) {
            xml.text dateEnding
          }
      elsif dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start") {
            xml.text dateStarted
          }
          xml.dateCreated(:encoding=>"w3cdtf", :point=>"end") {
            xml.text dateEnding
          }
      elsif dateStarted != nil && dateStarted.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
      elsif dateStarted != nil && dateStarted.length > 0
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes") {
            xml.text dateStarted
          }
      elsif dateOther != nil && dateOther.length > 0
          xml.dateOther {
            xml.text dateOther
          }
      else
        #puts "error in dates?"

      end
    end


    def insert_date(dateStarted=nil, dateEnding=nil, dateQualifier=nil, dateOther=nil)
      #begin

        if self.find_by_terms(:origin_info) != nil && self.find_by_terms(:origin_info).slice(0) != nil
          add_child_node(self.find_by_terms(:origin_info).slice(0), :date_partial, dateStarted, dateEnding, dateQualifier, dateOther)
        else
          add_child_node(ng_xml.root, :date, dateStarted, dateEnding, dateQualifier, dateOther)
        end

      #rescue OM::XML::Terminology::BadPointerError
        #add_child_node(ng_xml.root, :date, dateStarted, dateEnding, dateQualifier, dateOther)
      #end


    end

    def remove_date(index)
      self.find_by_terms(:date).slice(index.to_i).remove
    end

    define_template :date_issued do |xml, dateStarted, dateEnding, dateQualifier|

      if dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.originInfo {
          xml.dateIssued(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
          xml.dateIssued(:encoding=>"w3cdtf", :point=>"end", :qualifier=>dateQualifier) {
            xml.text dateEnding
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0
        xml.originInfo {
          xml.dateIssued(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start") {
            xml.text dateStarted
          }
          xml.dateIssued(:encoding=>"w3cdtf", :point=>"end") {
            xml.text dateEnding
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.originInfo {
          xml.dateIssued(:encoding=>"w3cdtf", :keyDate=>"yes", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0
        xml.originInfo {
          xml.dateIssued(:encoding=>"w3cdtf", :keyDate=>"yes") {
            xml.text dateStarted
          }
        }
      else
        #puts "error in dates?"

      end
    end

    define_template :date_issued_partial do |xml, dateStarted, dateEnding, dateQualifier|

      if dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.dateIssued(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start", :qualifier=>dateQualifier) {
          xml.text dateStarted
        }
        xml.dateIssued(:encoding=>"w3cdtf", :point=>"end", :qualifier=>dateQualifier) {
          xml.text dateEnding
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0
        xml.dateIssued(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start") {
          xml.text dateStarted
        }
        xml.dateIssued(:encoding=>"w3cdtf", :point=>"end") {
          xml.text dateEnding
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.dateIssued(:encoding=>"w3cdtf", :keyDate=>"yes", :qualifier=>dateQualifier) {
          xml.text dateStarted
        }
      elsif dateStarted != nil && dateStarted.length > 0
        xml.dateIssued(:encoding=>"w3cdtf", :keyDate=>"yes") {
          xml.text dateStarted
        }
      else
        #puts "error in dates?"

      end
    end

    def insert_date_issued(dateStarted=nil, dateEnding=nil, dateQualifier=nil)
      #begin
      if self.find_by_terms(:origin_info) != nil && self.find_by_terms(:origin_info).slice(0) != nil
        add_child_node(self.find_by_terms(:origin_info).slice(0), :date_issued_partial, dateStarted, dateEnding, dateQualifier)
      else
        add_child_node(ng_xml.root, :date_issued, dateStarted, dateEnding, dateQualifier)
      end

      #rescue OM::XML::Terminology::BadPointerError
      #add_child_node(ng_xml.root, :date, dateStarted, dateEnding, dateQualifier, dateOther)
      #end


    end




    define_template :date_copyright do |xml, dateStarted, dateEnding, dateQualifier|

      if dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.originInfo {
          xml.copyrightDate(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
          xml.copyrightDate(:encoding=>"w3cdtf", :point=>"end", :qualifier=>dateQualifier) {
            xml.text dateEnding
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0
        xml.originInfo {
          xml.copyrightDate(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start") {
            xml.text dateStarted
          }
          xml.copyrightDate(:encoding=>"w3cdtf", :point=>"end") {
            xml.text dateEnding
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.originInfo {
          xml.copyrightDate(:encoding=>"w3cdtf", :keyDate=>"yes", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
        }
      elsif dateStarted != nil && dateStarted.length > 0
        xml.originInfo {
          xml.copyrightDate(:encoding=>"w3cdtf", :keyDate=>"yes") {
            xml.text dateStarted
          }
        }
      else
        #puts "error in dates?"

      end
    end

    define_template :date_copyright_partial do |xml, dateStarted, dateEnding, dateQualifier|

      if dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.copyrightDate(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start", :qualifier=>dateQualifier) {
          xml.text dateStarted
        }
        xml.copyrightDate(:encoding=>"w3cdtf", :point=>"end", :qualifier=>dateQualifier) {
          xml.text dateEnding
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateEnding != nil && dateEnding.length > 0
        xml.copyrightDate(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start") {
          xml.text dateStarted
        }
        xml.copyrightDate(:encoding=>"w3cdtf", :point=>"end") {
          xml.text dateEnding
        }
      elsif dateStarted != nil && dateStarted.length > 0 && dateQualifier!= nil && dateQualifier.length > 0
        xml.copyrightDate(:encoding=>"w3cdtf", :keyDate=>"yes", :qualifier=>dateQualifier) {
          xml.text dateStarted
        }
      elsif dateStarted != nil && dateStarted.length > 0
        xml.copyrightDate(:encoding=>"w3cdtf", :keyDate=>"yes") {
          xml.text dateStarted
        }
      else
        #puts "error in dates?"

      end
    end

    def insert_date_copyright(dateStarted=nil, dateEnding=nil, dateQualifier=nil)
      #begin
      if self.find_by_terms(:origin_info) != nil && self.find_by_terms(:origin_info).slice(0) != nil
        add_child_node(self.find_by_terms(:origin_info).slice(0), :date_copyright_partial, dateStarted, dateEnding, dateQualifier)
      else
        add_child_node(ng_xml.root, :date_copyright, dateStarted, dateEnding, dateQualifier)
      end


    end



=begin
    define_template :internet_media do |xml, value|
      xml.internetMediaType(value)
    end


    def insert_internet_media(value=nil)
      if(value != nil && value.length > 1 && value != "image/jpeg")
        add_child_node(self.find_by_terms(:physical_description).slice(0), :internet_media, value)
      end
    end

    def remove_value(index)
      self.find_by_terms(:internet_media).slice(index.to_i).remove
    end
=end


    define_template :extent do |xml, extent|
      xml.extent(extent)
    end

    def insert_extent(extent=nil)
      self.mods(0).physical_description(0).extent(0, extent) unless extent.blank?
    end

    def remove_extent(index)
      self.find_by_terms(:extent).slice(index.to_i).remove
    end

    def insert_note(note=nil, noteQualifier=nil)
      note_index = self.mods(0).note.count
      self.mods(0).note(note_index, note) unless note.blank?
      self.mods(0).note(note_index).type_at = noteQualifier unless noteQualifier.blank?
    end

    def remove_note(index)
      self.find_by_terms(:note).slice(index.to_i).remove
    end


    def insert_subject_topic(topic=nil, valueURI=nil, authority=nil)
      if topic.present? && !self.mods(0).subject.topic.include?(topic)
        subject_index = self.mods(0).subject.count
        self.mods(0).subject(subject_index).topic = topic unless topic.blank?
        self.mods(0).subject(subject_index).valueURI = valueURI unless valueURI.blank?
        self.mods(0).subject(subject_index).authority = authority unless authority.blank?
        if authority == 'lctgm'
          self.mods(0).subject(subject_index).authorityURI = 'http://id.loc.gov/vocabulary/graphicMaterials'
        elsif authority == 'lcsh'
          self.mods(0).subject(subject_index).authorityURI = 'http://id.loc.gov/authorities/subjects'
        end

      end
    end

    def remove_subject_topic(index)
      self.find_by_terms(:mods, :subject_topic).slice(index.to_i).remove
    end

    def insert_series(series)
      if series.present?
        top_level_insert_position = self.mods(0).related_item.length

        0.upto self.mods(0).related_item.length-1 do |pos|
          if self.mods(0).related_item(pos).type == ['series']
            top_level_insert_position = pos
          end
        end

        if self.mods(0).related_item(top_level_insert_position).blank?
          self.mods(0).related_item(top_level_insert_position).type = 'series'
          self.mods(0).related_item(top_level_insert_position).title_info.title = series
        elsif self.mods(0).related_item(top_level_insert_position).related_item(0).blank?
          self.mods(0).related_item(top_level_insert_position).related_item(0).type = 'series'
          self.mods(0).related_item(top_level_insert_position).related_item(0).title_info.title = series
        elsif self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).blank?
          self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).type = 'series'
          self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).title_info.title = series
        elsif self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).related_item(0).blank?
          self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).related_item(0).type = 'series'
          self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).related_item(0).title_info.title = series
        elsif self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).related_item(0).related_item(0).blank?
          self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).related_item(0).related_item(0).type = 'series'
          self.mods(0).related_item(top_level_insert_position).related_item(0).related_item(0).related_item(0).related_item(0).title_info.title = series
        end

      end

    end

    def insert_subject_temporal(date)
      converted = Bplmodels::DatastreamInputFuncs.convert_to_mods_date(date)
      subject_index = self.mods(0).subject.count

      if converted.has_key?(:single_date)
        temporal_index = self.mods(0).subject(subject_index).temporal.length
        self.mods(0).subject(subject_index).temporal(temporal_index, converted[:single_date]) unless converted[:single_date].blank?
      elsif converted.has_key?(:date_range)
        temporal_index = self.mods(0).subject(subject_index).temporal.length
        self.mods(0).subject(subject_index).temporal(temporal_index, converted[:date_range][:start]) unless converted[:date_range][:start].blank?
        self.mods(0).subject(subject_index).temporal(temporal_index).point = 'start' unless converted[:date_range][:start].blank?

        temporal_index = self.mods(0).subject(subject_index).temporal.length
        self.mods(0).subject(subject_index).temporal(temporal_index, converted[:date_range][:end]) unless converted[:date_range][:end].blank?
        self.mods(0).subject(subject_index).temporal(temporal_index).point = 'end' unless converted[:date_range][:end].blank?
      end

    end

    def insert_abstract(abstract=nil)
      abstract_index = self.mods(0).abstract.count

      self.mods(0).abstract(abstract_index, abstract) unless abstract.blank?
    end

    def insert_subject_name(name=nil, type=nil, authority=nil, valueURI=nil, date=nil)
      subject_index = self.mods(0).subject.count

      if name.is_a?String
        self.mods(0).subject(subject_index).name(0).name_part_actual(0, name)
        #Date
        self.mods(0).subject(subject_index).name(0).name_part_actual(1, date) unless date.blank?
        self.mods(0).subject(subject_index).name(0).name_part_actual(1).type = 'date' unless date.blank?

      elsif name.is_a?Array
        name.each_with_index do |name_part, index|
          self.mods(0).subject(subject_index).name(0).name_part_actual(index,  Bplmodels::DatastreamInputFuncs.utf8Encode(name_part))

        end

      end

      self.mods(0).subject(subject_index).name(0).authority = authority unless authority.blank?
      self.mods(0).subject(subject_index).name(0).authority_uri = 'http://id.loc.gov/authorities/names' if authority == 'naf'
      self.mods(0).subject(subject_index).name(0).value_uri = valueURI unless valueURI.blank?
      self.mods(0).subject(subject_index).name(0).type = type unless type.blank?
    end

    define_template :subject_geographic do |xml, geographic, authority|
      if authority != nil and authority.length > 0
        xml.subject(:authority=>authority) {
          xml.geographic(geographic)
        }
      else
        xml.subject {
          xml.geographic(geographic)
        }
      end

    end


    def insert_subject_geographic(geographic=nil, valueURI=nil, authority=nil, coordinates=nil)
      if geographic.present?
        subject_index = self.mods(0).subject.count
        self.mods(0).subject(subject_index).geographic = geographic unless geographic.blank?
        self.mods(0).subject(subject_index).valueURI = valueURI unless valueURI.blank?
        self.mods(0).subject(subject_index).authority = authority unless authority.blank?
        if authority == 'lctgm'
          self.mods(0).subject(subject_index).authorityURI = 'http://id.loc.gov/vocabulary/graphicMaterials'
        elsif authority == 'lcsh'
          self.mods(0).subject(subject_index).authorityURI = 'http://id.loc.gov/authorities/subjects'
        end

        self.mods(0).subject(subject_index).cartographics(0).coordinates = coordinates unless coordinates.blank?

      end

    end

    def remove_subject_geographic(index)
      self.find_by_terms(:subject_geographic).slice(index.to_i).remove
    end


    def insert_subject_cartographic(coordinates=nil, scale=nil, projection=nil)
      subject_index =  self.mods(0).subject.count
      if coordinates.split(' ').length >= 3
        coordinates.scan(/([NSWE])([\d\.]+) *([NSWE])([\d\.]+) *([NSWE])([\d\.]+) *([NSWE])([\d\.]+)/).map do |dir1,deg1,dir2,deg2,dir3,deg3,dir4,deg4|
          deg1 = Float(deg1) * -1 if dir1 == 'S' || dir1 == 'W'
          deg2 = Float(deg2) * -1 if dir2 == 'S' || dir2 == 'W'
          deg3 = Float(deg3) * -1 if dir3 == 'S' || dir3 == 'W'
          deg4 = Float(deg4) * -1 if dir4 == 'S' || dir4 == 'W'

          if deg1 == deg2 && deg3 == deg4
            self.mods(0).subject(subject_index).cartographics(0).coordinates = deg3.to_s + ',' + deg1.to_s
          else
            self.mods(0).subject(subject_index).cartographics(0).coordinates = deg1.to_s + ' ' + deg4.to_s + ' ' + deg2.to_s + ' ' + deg3.to_s
          end
        end
      else
        self.mods(0).subject(subject_index).cartographics(0).coordinates = coordinates unless coordinates.blank?
      end

      self.mods(0).subject(subject_index).cartographics(0).scale = scale unless scale.blank?
      self.mods(0).subject(subject_index).cartographics(0).projection = projection unless projection.blank?

    end

    def remove_subject_cartographic(index)
      self.find_by_terms(:subject_cartographic).slice(index.to_i).remove
    end

    def insert_table_of_contents(value)
      contents_index = self.mods(0).table_of_contents.count
      self.mods(0).table_of_contents(contents_index, value) unless value.blank?
    end

    def remove_table_of_contents(index)
      self.find_by_terms(:table_of_contents).slice(index.to_i).remove
    end

    def insert_host(nonSort=nil, main_title=nil, identifier=nil, args={})

      related_index = self.mods(0).related_item.count

      self.mods(0).related_item(related_index).type = 'host' unless main_title.blank? && identifier.blank?
      self.mods(0).related_item(related_index).title_info(0).nonSort = nonSort unless nonSort.blank?
      self.mods(0).related_item(related_index).title_info(0).title = main_title unless main_title.blank?
      self.mods(0).related_item(related_index).identifier = identifier unless identifier.blank?

      args.each do |key, value|
        self.mods(0).related_item(related_index).send(key, Bplmodels::DatastreamInputFuncs.utf8Encode(value)) unless value.blank?
      end
    end

    def remove_host(index)
      self.find_by_terms(:mods, :host).slice(index.to_i).remove
    end




    define_template :related_item do |xml, value, qualifier|
      xml.relatedItem(:type=>qualifier) {
        xml.titleInfo {
          xml.title {
            xml.text value
          }
        }

      }
    end

    def insert_related_item(value=nil, qualifier=nil)
      if value != nil && value.length > 0
        add_child_node(ng_xml.root, :related_item, value, qualifier)
      end
    end

    def remove_related_item(index)
      self.find_by_terms(:related_item).slice(index.to_i).remove
    end


    define_template :related_item_xref do |xml, value|
      xml.relatedItem(:type=>"isReferencedBy", 'xlink:href'=>value)
    end

    def insert_related_item_xref(value=nil)
      puts 'told to insert related item xref'
      if value != nil && value.length > 0
        add_child_node(ng_xml.root, :related_item_xref, value)
      end
    end

    def related_item_xref(index)
      self.find_by_terms(:related_item_xref).slice(index.to_i).remove
    end

    def insert_related_item_url(value=nil)
      related_index = self.mods(0).related_item.count

      self.mods(0).related_item(related_index).location(0).url = value unless value.blank?
    end

    def remove_physical_location(index)
      self.find_by_terms(:physical_location).slice(index.to_i).remove
    end

    def insert_physical_location(location=nil, sublocation=nil,shelf_locator=nil)
      #Create a new tag unless there is a non-url tag already...
      location_index = self.mods(0).item_location.count

      for index in 0..self.mods(0).item_location.count-1
        if self.mods(0).item_location(index).url.blank?
          location_index = index
        end
      end

      physical_location_index = 0

      self.mods(0).item_location(location_index).physical_location(physical_location_index, location) unless location.blank?
      self.mods(0).item_location(location_index).holding_simple(0).copy_information(0).sub_location = sublocation unless sublocation.blank?
      self.mods(0).item_location(location_index).holding_simple(0).copy_information(0).shelf_locator = shelf_locator unless shelf_locator.blank?
    end

    def insert_location_url(url=nil, access=nil, usage=nil)
      location_index = self.mods(0).item_location.count

      self.mods(0).item_location(location_index).url = url unless url.blank?
      self.mods(0).item_location(location_index).url(0).usage = usage unless usage.blank?
      self.mods(0).item_location(location_index).url(0).access = access unless access.blank?

    end


    define_template :identifier do |xml, identifier, type, display_label|
      if display_label == nil
        xml.identifier(:type=>type) {
          xml.text identifier
        }
      else
        xml.identifier(:type=>type, :displayLabel=>display_label) {
          xml.text identifier
        }
      end
    end

    def insert_identifier(identifier=nil, type=nil, display_label=nil)
      if identifier.length > 0
        add_child_node(ng_xml.root, :identifier, identifier, type, display_label)
      end
    end

    def remove_identifier(index)
      self.find_by_terms(:identifier).slice(index.to_i).remove
    end


  define_template :mcgreevy do |xml|
    xml.recordInfo {
      xml.recordContentSource {
        xml.text "Boston Public Library"
      }
      xml.recordOrigin {
        xml.text "human prepared"
      }
      xml.languageOfCataloging {
        xml.languageTerm(:authority=>"iso639-2b", :authorityURI=>"http://id.loc.gov/vocabulary/iso639-2", :type=>'text', :valueURI=>"http://id.loc.gov/vocabulary/iso639-2/eng") {
          xml.text "English"
        }
      }

    }
  end

  def insert_mcgreevy
    add_child_node(ng_xml.root, :mcgreevy)
  end

  def remove_mcgreevy(index)
    self.find_by_terms(:mcgreevy).slice(index.to_i).remove
  end


    def insert_record_information(record_content_source, record_content_authority=nil)
      self.mods(0).record_info(0).record_content_source = record_content_source unless record_content_source.blank?
      self.mods(0).record_info(0).record_content_source(0).authority = record_content_authority unless record_content_authority.blank?
      self.mods(0).record_info(0).record_origin = 'human prepared'
      self.mods(0).record_info(0).language_of_cataloging(0).language_term = 'English'
    end


    def insert_new_node(term)
      add_child_node(ng_xml.root, term)
    end

    def remove_node(term, index)
      node = self.find_by_terms(term.to_sym => index.to_i).first
      unless node.nil?
        node.remove
        self.dirty = true
      end
    end

  end
end
