module Bplmodels
  class OAIMetadata < ActiveFedora::OmDatastream
    include OM::XML::Document

    OAI_NS = 'http://www.bpl.org/repository/xml/ns/oai'
    OAI_SCHEMA = 'http://www.bpl.org/repository/xml/xsd/oai.xsd'
    OAI_PARAMS = {
        "version"            => "0.0.1",
        "xmlns:xlink"        => "http://www.w3.org/1999/xlink",
        "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns"              => OAI_NS,
        "xsi:schemaLocation" => "#{OAI_NS} #{OAI_SCHEMA}",
    }

    set_terminology do |t|
      t.root :path => 'oaiMetadata', :xmlns => OAI_NS

      t.ingestion_information(:path=>"ingestionInformation") {
        t.url(:path=>"url")
        t.oai_format(:path=>'format')
      }

      t.header_information(:path=>'headerInformation') {
        t.status(:path=>'status')
        t.identifer(:path=>'identifier')
        t.datestamp(:path=>'datestamp')
        t.set_spec(:path=>'setSpec')
      }

      t.original_record(:path=>"originalRecord")

    end

    def self.xml_template
      Nokogiri::XML::Builder.new do |xml|
        xml.oaiMetadata(OAI_PARAMS) {

          xml.ingestionInformation {
            xml.url
            xml.format
          }

          xml.headerInformation {
            xml.status
            xml.identifier
            xml.datestamp
            xml.setSpec
          }

          xml.original_record

        }
      end.doc
    end
  end
end