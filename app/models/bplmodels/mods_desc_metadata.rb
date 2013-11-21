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
      t.genre(:path => 'mods/oxns:genre') {
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
      }

      t.item_location(:path=>"location") {
        t.physical_location(:path=>"physicalLocation")
        t.holding_simple(:path=>"holdingSimple") {
          t.copy_information(:path=>"copyInformation") {
            t.sub_location(:path=>"subLocation")
            t.shelf_locator(:path=>"shelfLocator")
          }
        }
        t.url(:path=>"url")
      }


      #t.identifier_nonURI(:path=>"identifier[not(@type=uri)]")

      t.identifier_accession :path => 'identifier', :attributes => { :type => "accession number" }
      t.identifier_barcode :path => 'identifier', :attributes => { :type => "barcode" }
      t.identifier_bpldc :path => 'identifier', :attributes => { :type => "bpldc number" }
      t.identifier_other :path => 'identifier', :attributes => { :type => "other" }

      t.local_other :path => 'identifier', :attributes => { :type => "local-other" }

      t.local_accession :path => 'identifier', :attributes => { :type => "local-accession" }
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
        }
        t.identifier
      }

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
        t.text(:path=>'roleTerm',:attributes=>{:type=>'text', :authority=>'marcrelator', :authorityURI=>'http://id.loc.gov/vocabulary/relators'})
        t.valueURI(:path=>{:attribute=>'valueURI'})
        t.code(:path=>'roleTerm',:attributes=>{:type=>'code'})
      }

      t.language(:path=>"language") {
        t.language_term(:path=>"languageTerm") {
          t.lang_val_uri(:path=>{:attribute=>"valueURI"})
        }
      }

      t.record_info(:path=>'recordInfo') {
        t.description_standard(:path=>'descriptionStandard', :attributes=>{:authority=>"marcdescription"})
        t.record_content_source(:path=>'recordContentSource')
        t.record_origin(:path=>'recordOrigin')
      }

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

    define_template :physical_description do |xml, media_type, digital_origin, media_type2, note|
      if media_type2 != nil && note != nil && note.length > 0
        xml.physicalDescription {
          xml.internetMediaType {
            xml.text media_type
          }
          xml.internetMediaType {
            xml.text media_type2
          }
          xml.digitalOrigin {
            xml.text digital_origin
          }
          xml.note {
            xml.text note
          }

        }
      elsif media_type2 != nil
        xml.physicalDescription {
          xml.internetMediaType {
            xml.text media_type
          }
          xml.internetMediaType {
            xml.text media_type2
          }
          xml.digitalOrigin {
            xml.text digital_origin
          }

        }
      elsif note != nil && note.length > 0
        xml.physicalDescription {
          xml.internetMediaType {
            xml.text media_type
          }
          xml.digitalOrigin {
            xml.text digital_origin
          }
          xml.note {
            xml.text note
          }
        }
      else
        xml.physicalDescription {
          xml.internetMediaType {
            xml.text media_type
          }
          xml.digitalOrigin {
            xml.text digital_origin
          }

        }
      end

    end

    def insert_physical_description(media_type=nil, digital_origin=nil, media_type2=nil, note=nil)
      add_child_node(ng_xml.root, :physical_description, media_type, digital_origin, media_type2, note)
    end

    def remove_physical_description(index)
      self.find_by_terms(:physical_description).slice(index.to_i).remove
    end

    def insert_media_type(media_type=nil)
      physical_description_index = 0
      media_type_index = self.mods(0).physical_description(physical_description_index).internet_media_type.count
      self.mods(0).physical_description(physical_description_index).internet_media_type(media_type_index, media_type)
    end



    define_template :language do |xml, value, code|
      xml.language {
        xml.languageTerm(:type=>"text", :authority=>"iso639-2b", :authorityURI=>"http://id.loc.gov/vocabulary/iso639-2", :valueURI=>"http://id.loc.gov/vocabulary/iso639-2/#{code}") {
          xml.text value
        }
      }
    end

    def insert_language(value=nil, code='eng')
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


    define_template :type_of_resource do |xml, value, manuscript|
      if(manuscript == "x")
        xml.typeOfResource(:manuscript=>"yes") {
          xml.text value
        }
      else
        xml.typeOfResource {
          xml.text value
        }
      end

    end

    def insert_type_of_resource(value=nil, manuscript=nil)
      if value != nil && value.length > 0
        add_child_node(ng_xml.root, :type_of_resource, value, manuscript)
      end
    end

    def remove_type_of_resource(index)
      self.find_by_terms(:type_of_resource).slice(index.to_i).remove
    end

    def insert_publisher(publisher=nil, place=nil)
      origin_index = self.origin_info.count
      publisher_index = self.origin_info(origin_index).publisher.count
      place_index =  self.origin_info(origin_index).place.count

      self.origin_info(origin_index).publisher(publisher_index, publisher) unless publisher.blank?
      self.origin_info(origin_index).place(place_index).place_term = place unless place.blank?
    end

    def remove_publisher(index)
      self.find_by_terms(:mods, :publisher).slice(index.to_i).remove
    end


    define_template :genre do |xml, value, value_uri, authority, is_general|

      if is_general
        xml.genre(:authority=>authority, :authorityURI=>"http://id.loc.gov/vocabulary/graphicMaterials", :valueURI=>value_uri, :displayLabel=>"general") {
          xml.text value
        }
      else
        xml.genre(:authority=>authority, :authorityURI=>"http://id.loc.gov/vocabulary/graphicMaterials", :valueURI=>value_uri, :displayLabel=>"specific") {
          xml.text value
        }
      end

    end

    def insert_genre(value=nil, value_uri=nil, authority=nil, is_general=false)
      if value != nil && value.length > 1
        add_child_node(ng_xml.root, :genre, value, value_uri, authority, is_general)
      end
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
      subject_index = self.mods(0).subject.count
      api_result = Bplmodels::DatastreamInputFuncs.get_tgn_data(tgn_id)

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
    def insert_title(nonSort=nil, main_title=nil, usage=nil, supplied=nil, args={})
      title_index = self.mods(0).title_info.count
      self.mods(0).title_info(title_index).nonSort = nonSort unless nonSort.blank?
      self.mods(0).title_info(title_index).main_title = main_title unless main_title.blank?

      self.mods(0).title_info(title_index).usage = usage unless usage.blank?
      self.mods(0).title_info(title_index).supplied = 'yes' unless supplied.blank? || supplied == 'no'

      args.each do |key, value|
        self.mods(0).title_info(title_index).send(key, Bplmodels::DatastreamInputFuncs.utf8Encode(value)) unless value.blank?
      end
    end

    def remove_title(index)
      self.find_by_terms(:mods, :title_info).slice(index.to_i).remove
    end

    #image.descMetadata.find_by_terms(:name).slice(0).set_attribute("new", "true")


    def insert_name(name=nil, type=nil, authority=nil, value_uri=nil, role=nil, role_uri=nil, args={})
      name_index = self.mods(0).name.count
      self.mods(0).name(name_index).type = type unless type.blank?
      self.mods(0).name(name_index).authority = authority unless authority.blank?
      self.mods(0).name(name_index).valueURI = value_uri unless value_uri.blank?

      if role.present?
        self.mods(0).name(name_index).role.text = role unless role.blank?
        self.mods(0).name(name_index).role.valueURI = role_uri unless role_uri.blank?
      end

      if(authority == 'naf')
        self.mods(0).name(name_index).authorityURI = 'http://id.loc.gov/authorities/names'
      end

      if type == 'corporate'
        name_hash = Bplmodels::DatastreamInputFuncs.corpNamePartSplitter(name)
        0.upto name_hash.size do |hash_pos|
          self.mods(0).name(name_index).namePart.append = name
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

      if converted.has_key?(:single_date)
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
      if(extent != nil && extent.length > 1)
        add_child_node(self.find_by_terms(:physical_description).slice(0), :extent, extent)
      end
    end

    def remove_extent(index)
      self.find_by_terms(:extent).slice(index.to_i).remove
    end

    define_template :note do |xml, note, noteQualifier|
      if noteQualifier != nil && noteQualifier.length > 1
        xml.note(:type=>noteQualifier) {
          xml.text note
        }
      else
        xml.note {
          xml.text note
        }
      end
    end


    def insert_note(note=nil, noteQualifier=nil)
      if(note != nil && note.length > 1)
        add_child_node(ng_xml.root, :note, note, noteQualifier)
      end
    end

    def remove_note(index)
      self.find_by_terms(:note).slice(index.to_i).remove
    end


    def insert_subject_topic(topic=nil, valueURI=nil, authority=nil)
      if topic.present?
        subject_index = self.mods(0).subject.count
        self.mods(0).subject(subject_index).topic = topic unless topic.blank?
        self.mods(0).subject(subject_index).valueURI = valueURI unless valueURI.blank?
        self.mods(0).subject(subject_index).authority = authority unless authority.blank?
        if authority == 'lctgm'
          self.mods(0).subject(subject_index).authorityURI = 'http://id.loc.gov/vocabulary/graphicMaterials'
        end

      end
    end

    def remove_subject_topic(index)
      self.find_by_terms(:mods, :subject_topic).slice(index.to_i).remove
    end

    def insert_series(series)
      insert_position = self.related_item.length
      self.related_item(insert_position).type = 'series'
      self.related_item(insert_position).title_info.title = series
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

    #FIXME: doesn't support multiple!
    define_template :subject_name do |xml, name, type, authority, valueURI, date|
      if authority != nil && authority.length > 0
        if date != nil && date.length > 1
          if authority == 'naf' && valueURI != nil && valueURI.length > 0
            xml.subject {
              xml.name(:type=>type, :authority=>authority, :authorityURI=>'http://id.loc.gov/authorities/names', :valueURI=>valueURI) {
                xml.namePart {
                  xml.text name
                }
                xml.namePart(:type=>"date") {
                  xml.text date
                }
              }
            }
          elsif authority == 'naf'
            xml.subject {
              xml.name(:type=>type, :authority=>authority, :authorityURI=>'http://id.loc.gov/authorities/names') {
                xml.namePart {
                  xml.text name
                }
                xml.namePart(:type=>"date") {
                  xml.text date
                }
              }
            }
          elsif authority == 'local'
            xml.subject {
              xml.name(:type=>type, :authority=>authority) {
                xml.namePart {
                  xml.text name
                }
                xml.namePart(:type=>"date") {
                  xml.text date
                }
              }
            }
          else
            xml.subject {
              xml.name(:type=>type, :authority=>authority, :valueURI=>valueURI) {
                xml.namePart {
                  xml.text name
                }
                xml.namePart(:type=>"date") {
                  xml.text date
                }
              }
            }
          end

        #No date
        else
          if authority == 'naf'  && valueURI != nil && valueURI.length > 0
            xml.subject {
              xml.name(:type=>type, :authority=>authority, :authorityURI=>'http://id.loc.gov/authorities/names', :valueURI=>valueURI) {
                xml.namePart {
                  xml.text name
                }
              }
            }
          elsif authority == 'naf'
            xml.subject {
              xml.name(:type=>type, :authority=>authority, :authorityURI=>'http://id.loc.gov/authorities/names') {
                xml.namePart {
                  xml.text name
                }
              }
            }

          elsif authority == 'local'
            xml.subject {
              xml.name(:type=>type, :authority=>authority) {
                xml.namePart {
                  xml.text name
                }
              }
            }
          else
            xml.subject {
              xml.name(:type=>type, :authority=>authority, :valueURI=>valueURI) {
                xml.namePart {
                  xml.text name
                }
              }
            }
          end

        end
      else
        if date != nil && date.length > 1
          xml.subject {
            xml.name(:type=>type) {
              xml.namePart {
                xml.text name
              }
              xml.namePart(:type=>"date") {
                xml.text date
              }
            }
          }

        else
          xml.subject {
            xml.name(:type=>type) {
              xml.namePart {
                xml.text name
              }
            }
          }
        end
      end


    end

    def insert_subject_name(name=nil, type=nil, authority=nil, valueURI=nil, date=nil)
      add_child_node(ng_xml.root, :subject_name, name, type, authority, valueURI, date)
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



    define_template :geographic do |xml, topic|
        xml.geographic(topic)
    end

    def insert_subject_geographic(geographic=nil, authority=nil)
      if geographic != nil && geographic.length > 1
      #  if self.find_by_terms(:subject) != nil && self.find_by_terms(:subject).slice(0) != nil
      #    add_child_node(self.find_by_terms(:subject).slice(0), :geographic, geographic, authority)
      #  else
          add_child_node(ng_xml.root, :subject_geographic, geographic, authority)
      #  end
      end

    end

    def remove_subject_geographic(index)
      self.find_by_terms(:subject_geographic).slice(index.to_i).remove
    end


    define_template :subject_cartographic do |xml, coordinates, scale, projection|
      xml.subject {
        xml.cartographics {
          if coordinates != nil && coordinates.length > 1
            xml.coordinates(coordinates)
          end
          if scale != nil && scale.length > 1
            xml.scale(scale)
          end
          if projection != nil && projection.length > 1
            xml.projection(projection)
          end
        }
      }
    end

    def insert_subject_cartographic(coordinates=nil, scale=nil, projection=nil)
      add_child_node(ng_xml.root, :subject_cartographic, coordinates, scale, projection)
    end

    def remove_subject_cartographic(index)
      self.find_by_terms(:subject_cartographic).slice(index.to_i).remove
    end

    def insert_host(value=nil, identifier=nil, args={})
      related_index = self.mods(0).related_item.count

      self.mods(0).related_item(related_index).type = 'host' unless value.blank? && identifier.blank?
      self.mods(0).related_item(related_index).title_info(0).title = value unless value.blank?
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

    define_template :physical_location do |xml, location, sublocation, shelf_locator|

      xml.location {
        xml.physicalLocation {
          xml.text location
        }
        if sublocation != nil || shelf_locator != nil
          xml.holdingSimple {
            xml.copyInformation {
              if sublocation != nil
                xml.subLocation {
                  xml.text sublocation
                }
              end
              if shelf_locator != nil
                xml.shelfLocator {
                  xml.text shelf_locator
                }
              end
            }
          }
        end
      }
    end

    def insert_physical_location(location=nil, sublocation=nil, shelf_locator=nil)
      add_child_node(ng_xml.root, :physical_location, location, sublocation, shelf_locator)
    end

    def remove_physical_location(index)
      self.find_by_terms(:physical_location).slice(index.to_i).remove
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
