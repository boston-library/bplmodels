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
      t.root :path => 'workflowMetadata', :xmlns => WORKFLOW_NS

      t.item_status(:path=>"itemStatus") {
        t.state(:path=>"state")
        t.state_comment(:path=>"stateComment")
      }

      t.item_source(:path=>"itemSource") {
        t.ingest_origin(:path=>"ingestOrigin")
        t.ingest_filepath(:path=>"ingestFilepath") #Only supported later for file objects.
        t.ingest_filename(:path=>"ingestFilename") #Only recently added
      }

      t.item_designations(:path=>'itemDesignations') {
        t.flagged_for_content(:path=>"flaggedForContent")
      }

      t.marked_for_deletion(:path=>'markedForDelation') {
        t.reason(:path=>'reason')
      }

    end

    def self.xml_template
      Nokogiri::XML::Builder.new do |xml|
        xml.workflowMetadata(WORKFLOW_PARAMS) {

        }
      end.doc
    end


    def insert_file_path(value=nil)
      ingest_filepath_index = self.item_source.ingest_filepath.count

      self.item_source.ingest_filepath(ingest_filepath_index, value) unless value.blank? || self.item_source.ingest_filepath.include?(value)
    end

    def insert_file_name(value=nil)
      ingest_filename_index = self.item_source.ingest_filepath.count

      self.item_source.ingest_filename(ingest_filename_index, value) unless value.blank? || self.item_source.ingest_filepath.include?(value)
    end
  end
end