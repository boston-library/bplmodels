module Bplmodels
  class BookMetadata < ActiveFedora::OmDatastream
    include OM::XML::Document

    OAI_NS = 'http://www.bpl.org/repository/xml/ns/book'
    OAI_SCHEMA = 'http://www.bpl.org/repository/xml/xsd/book.xsd'
    OAI_PARAMS = {
        "version"            => "0.0.1",
        "xmlns:xlink"        => "http://www.w3.org/1999/xlink",
        "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns"              => OAI_NS,
        "xsi:schemaLocation" => "#{OAI_NS} #{OAI_SCHEMA}",
    }

    set_terminology do |t|
      t.root :path => 'book', :xmlns => OAI_NS

      t.page_data(:path=>"pageData") {
        t.page(:path=>"page") {
          t.page_type(:path=>'pageType')
          t.hand_size(:path=>'handSize')
          t.page_number(:path=>'pageNumber')
        }


      }

    end

    def self.xml_template
      builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
        xml.book(OAI_PARAMS) {
          xml.parent.namespace = xml.parent.namespace_definitions.find{|ns|ns.prefix=="book"}

        }
      end
      return builder.doc

    end

    #Required for Active Fedora 9
    def prefix(path=nil)
      return ''
    end


    define_template :original_record do |xml, content|
        xml.original_record {
          xml.cdata content
        }
    end


    def insert_original_record(content)
        add_child_node(ng_xml.root, :original_record, content)
    end

    def remove_original_record(index)
      self.find_by_terms(:original_record).slice(index.to_i).remove
    end
  end
end