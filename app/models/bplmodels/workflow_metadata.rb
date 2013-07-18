module Bplmodels
  class WorkflowMetadata < ActiveFedora::OmDatastream
    include OM::XML::Document

    WORKFLOW_NS = 'http://www.bpl.org/repository/xml/ns/workflow'
    WORKFLOW_SCHEMA = 'http://www.bpl.org/repository/xml/xsd/workflow.xsd'
    WORKFLOW_PARAMS = {
        "version"            => "0.0.1",
        "xmlns:xlink"        => "http://www.w3.org/1999/xlink",
        "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns"              => WORKFLOW_NS,
        "xsi:schemaLocation" => "#{WORKFLOW_NS} #{WORKFLOW_SCHEMA}",
    }

    set_terminology do |t|
      t.root :path => 'workflow', :xmlns => WORKFLOW_NS

      t.item_status(:path=>"itemStatus") {
        t.state(:path=>"state")
        t.state_comment(:path=>"stateComment")
      }

      t.item_source(:path=>"itemSource") {
        t.ingest_origin(:path=>"ingestOrigin")
        t.ingest_filepath(:path=>"ingestFilepath")
      }

    end

    def self.xml_template
      Nokogiri::XML::Builder.new do |xml|
        xml.mods(ADMIN_PARAMS) {

          xml.itemStatus {
            xml.state
            xml.stateComment
          }

          xml.itemSource {
            xml.ingestOrigin
            xml.ingestFilepath
          }

        }
      end.doc
    end
  end
end