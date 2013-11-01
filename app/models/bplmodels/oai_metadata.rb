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
        t.set_name(:path=>'setName')
      }

      t.header_information(:path=>'headerInformation') {
        t.status(:path=>'status')
        t.identifer(:path=>'identifier')
        t.datestamp(:path=>'datestamp')
        t.set_spec(:path=>'setSpec')
      }


      t.original_record(:path=>'originalRecord')

      t.raw_info(:path=>'rawInfo') {
        t.file_urls(:path=>'fileURL') {
          t.index(:path=>{:attribute=>"index"})
        }
        t.unparsed_dates(:path=>'unparsedDates')
      }


    end

    def self.xml_template
      Nokogiri::XML::Builder.new do |xml|
        xml.oaiMetadata(OAI_PARAMS) {



        }
      end.doc
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