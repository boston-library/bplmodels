require 'mods'

module Bplmodels
  class ModsDescMetadata < ActiveFedora::OmDatastream
    #include Hydra::Datastream::CommonModsIndexMethods
    # MODS XML constants.

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

      t.abstract_plain(:path=>"abstract", :attributes=>{:displayLabel=>"Plain Text"})

      t.abstract_html(:path=>"abstract", :attributes=>{:displayLabel=>"HTML Text"})



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
      t.identifier(:path => 'mods/oxns:identifier') {
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
          if dv.empty?
            if name_node.type_at == 'personal'
              if name_node.family_name.size > 0
                dv = name_node.given_name.size > 0 ? "#{name_node.family_name.text}, #{name_node.given_name.text}" : name_node.family_name.text
              elsif name_node.given_name.size > 0
                dv = name_node.given_name.text
              end
              if !dv.empty?
                first = true
                name_node.namePart.each { |np|
                  if np.type_at == 'termsOfAddress' && !np.text.empty?
                    if first
                      dv = dv + " " + np.text
                      first = false
                    else
                      dv = dv + ", " + np.text
                    end
                  end
                }
              else # no family or given name
                dv = name_node.namePart.select {|np| np.type_at != 'date' && !np.text.empty?}.join(" ")
              end
            else # not a personal name
              dv = name_node.namePart.select {|np| np.type_at != 'date' && !np.text.empty?}.join(" ")
            end
          end
          dv.strip.empty? ? nil : dv.strip
        }

        # name convenience method
        n.display_value_w_date :path => '.', :single => true, :accessor => lambda {|name_node|
          dv = ''
          dv = dv + name_node.display_value if name_node.display_value
          name_node.namePart.each { |np|
            if np.type_at == 'date' && !np.text.empty? && !dv.end_with?(np.text)
              dv = dv + ", #{np.text}"
            end
          }
          if dv.start_with?(', ')
            dv.sub(', ', '')
          end
          dv.strip.empty? ? nil : dv.strip
        }
      } # t._plain_name

      t.personal_name :path => '/m:mods/m:name[@type="personal"]'
      t._personal_name :path => '//m:name[@type="personal"]'
      t.corporate_name :path => '/m:mods/m:name[@type="corporate"]'
      t._corporate_name :path => '//m:name[@type="corporate"]'
      t.conference_name :path => '/m:mods/m:name[@type="conference"]'
      t._conference_name :path => '//m:name[@type="conference"]'
=end





      t.title_info(:path=>"titleInfo") {
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

      t.name(:path=>"mods/oxns:name") {
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

      t.type_of_resource(:path=>"typeOfResource")


      t.genre_basic(:path=>"genre", :attributes=>{:displayLabel => "general"})

      t.genre_specific(:path=>"genre", :attributes=>{:displayLabel => "specific"})

      t.origin_info(:path=>"originInfo") {
        t.publisher(:path=>"publisher")
      }

      t.related_item(:path=>"relatedItem", :attributes=>{ :type => "host"}) {
      }

      t.item_location(:path=>"location") {
        t.physical_location(:path=>"physicalLocation")
        t.holding_simple(:path=>"holdingSimple") {
          t.copy_information(:path=>"copyInformation") {
            t.sub_location(:path=>"subLocation")
          }
        }
        t.url(:path=>"url")
      }



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
      }

      t.note(:path=>"note") {
        t.type_at(:path=>{:attribute=>"type"})
      }

      t.test1(:path=>'mods/oxns:subject/oxns:name') {
        t.name_part(:path=>"namePart[not(@type)]")
        t.date(:path=>"namePart", :attributes=>{:type=>"date"})
      }

      t.test2(:path=>'subject/oxns:name') {
        t.name_part(:path=>"namePart[not(@type)]")
        t.date(:path=>"namePart", :attributes=>{:type=>"date"})
      }

      t.test3(:path=>'name') {
        t.name_part(:path=>"namePart[not(@type)]")
        t.date(:path=>"namePart", :attributes=>{:type=>"date"})
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
        t.personal_name(:path=>'name', :attributes=>{:type => "personal"}) {
          t.name_part(:path=>"namePart[not(@type)]")
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
        }
        t.corporate_name(:path=>'name', :attributes=>{:type => "corporate"}) {
          t.name_part(:path=>"namePart[not(@type)]")
          t.date(:path=>"namePart", :attributes=>{:type=>"date"})
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
        t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
        t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
      }

      t.language(:path=>"language") {
        t.language_term(:path=>"languageTerm") {
          t.lang_val_uri(:path=>{:attribute=>"valueURI"})
        }
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
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(MODS_PARAMS) {
          xml.parent.namespace = xml.parent.namespace_definitions.find{|ns|ns.prefix=="mods"}

          xml.abstract

        }
      end
      return builder.doc
    end

    define_template :physical_description do |xml, media_type, digital_origin, media_type2|
      if media_type2 != nil
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

    def insert_physical_description(media_type=nil, digital_origin=nil, media_type2=nil)
      add_child_node(ng_xml.root, :physical_description, media_type, digital_origin, media_type2)
    end

    def remove_physical_description(index)
      self.find_by_terms(:physical_description).slice(index.to_i).remove
    end



    define_template :language do |xml, value|
      xml.language {
        xml.languageTerm(:authority=>"iso639-2b", :authorityURI=>"http://id.loc.gov/vocabulary/iso639-2", :valueURI=>"http://id.loc.gov/vocabulary/iso639-2/eng", :lang=>"eng") {
          xml.text "English"
        }
      }
    end

    def insert_language(value=nil)
      add_child_node(ng_xml.root, :language, value)
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

    define_template :publisher do |xml, value|
      xml.originInfo {
        xml.publisher {
          xml.text value
        }
      }
    end

    def insert_publisher(value=nil)
      if(value != nil && value.length > 1)
        add_child_node(ng_xml.root, :publisher, value)
      end
    end

    def remove_publisher(index)
      self.find_by_terms(:publisher).slice(index.to_i).remove
    end


    define_template :genre do |xml, value, authority, value_uri, is_general|

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

    define_template :title_info do |xml, nonSort, main_title, usage, supplied, subtitle, language, type, authority, authorityURI, valueURI|
      if nonSort!=nil && main_title!=nil && subtitle!=nil && language!=nil && supplied!=nil && type!=nil && usage!=nil && authority!=nil && authorityURI!=nil && valueURI!=nil
        xml.titleInfo(:language=>language, :supplied=>supplied, :type=>type, :usage=>usage, :authority=>authority, :authorityURI=>authorityURI, :valueURI=>valueURI) {
          xml.nonSort(nonSort)
          xml.title(main_title)
          xml.subtitle(subtitle)
        }
      elsif usage != nil && nonSort!=nil && main_title != nil && supplied != nil && supplied.strip.downcase == "x"
        xml.titleInfo(:usage=>usage, :supplied=>"yes") {
          xml.nonSort(nonSort)
          xml.title(main_title)
        }
      elsif usage != nil && nonSort!=nil && main_title != nil
        xml.titleInfo(:usage=>usage) {
          xml.nonSort(nonSort)
          xml.title(main_title)
        }
      elsif usage != nil && main_title != nil && supplied != nil && supplied.strip.downcase == "x"
        xml.titleInfo(:usage=>usage, :supplied=>"yes") {
          xml.title(main_title)
        }
      elsif usage != nil && main_title != nil
        xml.titleInfo(:usage=>usage) {
          xml.title(main_title)
        }

      elsif nonSort!=nil && main_title != nil
        xml.titleInfo {
          xml.nonSort(nonSort)
          xml.title(main_title)
        }
      elsif main_title != nil
        xml.titleInfo {
          xml.title(main_title)
        }
      end
    end

    def insert_title(nonSort=nil, main_title=nil, usage=nil,  supplied=nil, subtitle=nil, language=nil, type=nil, authority=nil, authorityURI=nil, valueURI=nil)
      add_child_node(ng_xml.root, :title_info, nonSort, main_title, usage, supplied, subtitle, language, type, authority, authorityURI, valueURI)
    end

    #image.descMetadata.find_by_terms(:name).slice(0).set_attribute("new", "true")


    def remove_title(index)
      self.find_by_terms(:title_info).slice(index.to_i).remove
    end


    define_template :name do |xml, name, type, authority, role, uri|
      if type != nil && type.length > 1 && authority !=nil && authority.length > 1 && uri !=nil && uri.length > 1
        xml.name(:type=>type, :authority=>authority) {
          xml.role {
            xml.roleTerm(:type=>"text", :authority=>"marcrelator", :authorityURI=>"http://id.loc.gov/vocabulary/relators", :valueURI=>uri)   {
              xml.text role
            }
          }
          xml.namePart(name)
        }
      elsif type != nil && type.length > 1 && authority !=nil && authority.length > 1
        xml.name(:type=>type, :authority=>authority) {
          xml.role {
            xml.roleTerm(:type=>"text", :authority=>"marcrelator")   {
              xml.text role
            }
          }
          xml.namePart(name)
        }
      elsif type != nil && type.length > 1
        xml.name(:type=>type) {
          xml.role {
            xml.roleTerm(:type=>"text", :authority=>"marcrelator")   {
              xml.text role
            }
          }
          xml.namePart(name)
        }
      else
        xml.name {
          xml.role {
            xml.roleTerm(:type=>"text", :authority=>"marcrelator")   {
              xml.text role
            }
          }
          xml.namePart(name)
        }
      end

    end

    def insert_name(name=nil, type=nil, authority=nil, role=nil, uri=nil)
      add_child_node(ng_xml.root, :name, name, type, authority, role, uri)
    end

    define_template :namePart do |xml, name|
      xml.namePart(:type=>"date") {
        xml.text name
      }
    end

    define_template :namePartDate do |xml, date|
      xml.namePart(:type=>"date") {
        xml.text date
      }
    end

    #test = ["test1", "test2"]
    #test.each do |k|
      #define_method "current_#{k.underscore}" do
        #puts k.underscore
      #end
    #end



    def insert_namePart(index, name=nil)
      add_child_node(self.find_by_terms(:name).slice(index.to_i), :namePart, name)
    end

    def insert_namePartDate(index, date=nil)
      add_child_node(self.find_by_terms(:name).slice(index.to_i), :namePartDate, date)
    end


    def remove_name(index)
      self.find_by_terms(:name).slice(index.to_i).remove
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

    define_template :subject_topic do |xml, topic, uri, authority|
      if(authority != nil && authority.length > 1 && uri != nil && uri.length > 1)
      xml.subject(:authority=>authority, :authorityURI=>"http://id.loc.gov/vocabulary/graphicMaterials", :valueURI=>uri) {
        xml.topic(topic)
      }
      elsif(authority != nil && authority.length > 1)
        xml.subject(:authority=>authority) {
          xml.topic(topic)
        }
      else
        xml.subject {
          xml.topic(topic)
        }
      end

    end


    define_template :topic do |xml, topic|
      xml.topic(topic)
    end

    def insert_subject_topic(topic=nil, uri=nil, authority=nil)
      if(topic != nil && topic.length > 1)
        #if self.find_by_terms(:subject) != nil && self.find_by_terms(:subject).slice(0) != nil && authority == nil && type == nil
          #add_child_node(self.find_by_terms(:subject).slice(0), :topic, topic, type, authority)
        #elsif self.find_by_terms(:subject).slice(1) != nil && authority != nil && type != nil
          #add_child_node(self.find_by_terms(:subject).slice(1), :topic, topic, type, authority)
        #else
          add_child_node(ng_xml.root, :subject_topic, topic, uri, authority)
        #end
      end
    end

    def remove_subject_topic(index)
      self.find_by_terms(:subject_topic).slice(index.to_i).remove
    end

    #FIXME: doesn't support multiple!
    define_template :subject_name do |xml, name, type, authority, date|
      if date != nil && date.length > 1
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
          xml.name(:type=>type, :authority=>authority) {
            xml.namePart {
              xml.text name
            }
          }
        }
      end

    end

    def insert_subject_name(name=nil, type=nil, authority=nil, date=nil)
      add_child_node(ng_xml.root, :subject_name, name, type, authority, date)
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

    define_template :host do |xml, value, identifier|
      xml.relatedItem(:type=>"host") {
        xml.titleInfo {
          xml.title {
            xml.text value
          }
        }
        if(identifier != nil && identifier.length > 0)
          xml.identifier(:type=>"uri") {
            xml.text identifier
          }
        end
    }
    end

    def insert_host(value=nil, identifier=nil)
      add_child_node(ng_xml.root, :host, value, identifier)
    end

    def remove_host(index)
      self.find_by_terms(:host).slice(index.to_i).remove
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



    define_template :physical_location do |xml, location, sublocation|

      xml.location {
        xml.physicalLocation {
          xml.text location
        }
        if sublocation != nil
          xml.holdingSimple {
            xml.copyInformation {
              xml.subLocation {
                xml.text sublocation
              }
            }
          }
        end
      }
    end

    def insert_physical_location(location=nil, sublocation=nil)
      add_child_node(ng_xml.root, :physical_location, location, sublocation)
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
      xml.languageOfCataloging(:usage=>"primary") {
        xml.languageTerm(:authority=>"iso639-2b", :authorityURI=>"http://id.loc.gov/vocabulary/iso639-2", :valueURI=>"http://id.loc.gov/vocabulary/iso639-2/eng")
      }
      xml.descriptionStandard(:authority=>"marcdescription") {
        xml.text "gihc"
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
