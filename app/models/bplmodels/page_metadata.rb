module Bplmodels
  class PageMetadata < ActiveFedora::OmDatastream
    include OM::XML::Document

    OAI_NS = 'http://www.bpl.org/repository/xml/ns/page'
    OAI_SCHEMA = 'http://www.bpl.org/repository/xml/xsd/page.xsd'
    OAI_PARAMS = {
        "version"            => "0.0.1",
        "xmlns:xlink"        => "http://www.w3.org/1999/xlink",
        "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns"              => OAI_NS,
        "xsi:schemaLocation" => "#{OAI_NS} #{OAI_SCHEMA}",
    }

    set_terminology do |t|
      t.root :path => 'pageData', :xmlns => OAI_NS

      t.page(:path=>"page") {
        t.page_type(:path=>'pageType')
        t.hand_side(:path=>'handSide')
        t.page_number(:path=>'pageNumber') {
          t.sequence(:path=>{:attribute=>"sequence"})
        }
        t.has_djvu(:path=>'hasDJVU')
        t.has_ocrMaster(:path=>'hasOCRMaster')


      }

    end

    def self.xml_template
=begin
      builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
        xml.book(OAI_PARAMS) {
          xml.parent.namespace = xml.parent.namespace_definitions.find{|ns|ns.prefix=="book"}

        }
      end
      return builder.doc
=end
      Nokogiri::XML::Builder.new do |xml|
        xml.pageData(OAI_PARAMS) {

        }
      end.doc

    end

    #Required for Active Fedora 9
    def prefix(path=nil)
      return ''
    end

  end
end