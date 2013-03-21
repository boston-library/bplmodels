module Bplmodels
  class ModsDescCollectionMetadata < ActiveFedora::NokogiriDatastream
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
      t.root :path => 'mods', :xmlns => MODS_NS
      t.originInfo  do
        t.dateOther
      end
      t.abstract

      t.title_info(:path=>"titleInfo") {
        t.usage(:path=>{:attribute=>"usage"})
        t.nonSort(:path=>"nonSort")
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

      t.name {
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

      t.genre(:path=>"genre", :attributes=>{ :type => "gmgpc"})

      t.origin_info(:path=>"originInfo") {
        t.publisher(:type=>:string)
      }

      t.related_item(:path=>"relatedItem", :attributes=>{ :type => "host"}) {
      }

      t.ark_uri(:path=>"identifier", :attributes=>{ :type => "uri"}) {
      }

      t.item_location(:path=>"location") do
        t.physical_location(:path=>"physicalLocation")
          #t.holding_simple(:path=>"holdingSimple") {
            #t.copy_information(:path=>"copyInformation") {
              #t.sub_location(:path=>"subLocation")
           # }
          #}
        #}
      end



      t.identifier_accession :path => 'identifier', :attributes => { :type => "accession number" }
      t.identifier_barcode :path => 'identifier', :attributes => { :type => "barcode" }
      t.identifier_bpldc :path => 'identifier', :attributes => { :type => "bpldc number" }
      t.identifier_other :path => 'identifier', :attributes => { :type => "other" }



      t.subject  do
        t.topic
      end

      t.role {
        t.text(:path=>"roleTerm",:attributes=>{:type=>"text"})
        t.code(:path=>"roleTerm",:attributes=>{:type=>"code"})
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

          xml.language {
            xml.languageTerm(:authority=>"iso639-2b", :authorityURI=>"http://id.loc.gov/vocabulary/iso639-2", :valueURI=>"http://id.loc.gov/vocabulary/iso639-2/eng", :lang=>"eng")
          }

          xml.location {
            xml.physicalLocation {
            }
          }

          xml.accessCondition(:type=>"use and reproduction") {
            xml.text "Contact host institution for more information."
          }

          xml.abstract

        }
      end
      return builder.doc
    end

    define_template :access_links do |xml, primary|
      xml.location {
        xml.url(:access=>"primary", :access=>"object in context") {
          xml.text primary
        }
      }
    end

    def insert_access_links(primary=nil)
      add_child_node(ng_xml.root, :access_links, primary)
    end

    def remove_access_links(index)
      self.find_by_terms(:access_links).slice(index.to_i).remove
    end

    define_template :title_info do |xml, nonSort, main_title, usage, subtitle, language, supplied, type, authority, authorityURI, valueURI|
      if nonSort!=nil && main_title!=nil && subtitle!=nil && language!=nil && supplied!=nil && type!=nil && usage!=nil && authority!=nil && authorityURI!=nil && valueURI!=nil
        xml.titleInfo(:language=>language, :supplied=>supplied, :type=>type, :usage=>usage, :authority=>authority, :authorityURI=>authorityURI, :valueURI=>valueURI) {
          xml.nonSort(nonSort)
          xml.title(main_title)
          xml.subtitle(subtitle)
        }
      elsif usage != nil && nonSort!=nil && main_title != nil
        xml.titleInfo(:usage=>usage) {
          xml.nonSort(nonSort)
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

    def insert_title(nonSort=nil, main_title=nil, usage=nil, subtitle=nil, language=nil, supplied=nil, type=nil, authority=nil, authorityURI=nil, valueURI=nil)
      add_child_node(ng_xml.root, :title_info, nonSort, main_title, usage, subtitle, language, supplied, type, authority, authorityURI, valueURI)
    end

    #image.descMetadata.find_by_terms(:name).slice(0).set_attribute("new", "true")


    def remove_title(index)
      self.find_by_terms(:title_info).slice(index.to_i).remove
    end


    define_template :name do |xml, name, type, role|

      xml.name(:type=>type) {
        xml.role {
          xml.roleTerm(:type=>"text", :authority=>"marcrelator")   {
             xml.text role
          }
        }
        xml.namePart(name)
      }
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

    def insert_name(name=nil, type=nil, role=nil)
      add_child_node(ng_xml.root, :name, name, type, role)
    end

    def insert_namePart(index, name=nil, date=nil)
      add_child_node(self.find_by_terms(:name).slice(index.to_i), :namePart, name)
    end

    def insert_namePartDate(index, name=nil, date=nil)
      add_child_node(self.find_by_terms(:name).slice(index.to_i), :namePart, name)
    end


    def remove_name(index)
      self.find_by_terms(:name).slice(index.to_i).remove
    end

    define_template :date do |xml, dateStarted, dateEnding, dateQualifier, dateOther|
      if dateStarted != nil && dateEnding != nil && dateQualifier!= nil
        xml.originInfo {
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
          xml.dateCreated(:encoding=>"w3cdtf", :point=>"end", :qualifier=>dateQualifier) {
            xml.text dateEnding
          }
        }
      elsif dateStarted != nil && dateEnding != nil
        xml.originInfo {
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start") {
            xml.text dateStarted
          }
          xml.dateCreated(:encoding=>"w3cdtf", :point=>"end") {
            xml.text dateEnding
          }
        }
      elsif dateStarted != nil && dateQualifier!= nil
        xml.originInfo {
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start", :qualifier=>dateQualifier) {
            xml.text dateStarted
          }
        }
      elsif dateStarted != nil
        xml.originInfo {
          xml.dateCreated(:encoding=>"w3cdtf", :keyDate=>"yes", :point=>"start") {
            xml.text dateStarted
          }
        }
      elsif dateOther != nil
        xml.originInfo {
          xml.dateOther {
            xml.text dateOther
          }
        }
      else
        puts "error in dates?"
      end
    end


    def insert_date(dateStarted=nil, dateEnding=nil, dateQualifier=nil, dateOther=nil)
      add_child_node(ng_xml.root, :date, dateStarted, dateEnding, dateQualifier, dateOther)
    end

    def remove_date(index)
      self.find_by_terms(:date).slice(index.to_i).remove
    end

    define_template :extent do |xml, extent|
      xml.physicalDescription {
        xml.extent(extent)
      }
    end


    def insert_extent(extent=nil)
      add_child_node(ng_xml.root, :extent, extent)
    end

    def remove_extent(index)
      self.find_by_terms(:extent).slice(index.to_i).remove
    end

    define_template :note do |xml, note, noteQualifier|
      xml.note(:type=>noteQualifier) {
        xml.text note
      }
    end


    def insert_note(note=nil, noteQualifier=nil)
      add_child_node(ng_xml.root, :note, note, noteQualifier)
    end

    def remove_note(index)
      self.find_by_terms(:note).slice(index.to_i).remove
    end

    define_template :subject_topic do |xml, topic, uri, authority|
      xml.subject {
        xml.topic(topic)
      }
    end


    def insert_subject_topic(topic=nil, uri=nil, authority=nil)
      add_child_node(ng_xml.root, :subject_topic, topic, uri, authority)
    end

    def remove_subject_topic(index)
      self.find_by_terms(:subject_topic).slice(index.to_i).remove
    end

    define_template :subject_geographic do |xml, geographic, authority|
      xml.subject {
        xml.geographic(geographic)
      }
    end

    def insert_subject_geographic(geographic=nil, authority=nil)
      add_child_node(ng_xml.root, :subject_geographic, geographic, authority)
    end

    def remove_subject_geographic(index)
      self.find_by_terms(:subject_geographic).slice(index.to_i).remove
    end


    define_template :identifier do |xml, identifier, type|
      xml.identifier(:type=>type) {
        xml.text identifier
      }
    end

    def insert_identifier(identifier=nil, type=nil)
      add_child_node(ng_xml.root, :identifier, identifier, type)
    end

    def remove_identifier(index)
      self.find_by_terms(:identifier).slice(index.to_i).remove
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
