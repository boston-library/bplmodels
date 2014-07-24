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
        t.processing(:path=>"processing")
        t.processing_comment(:path=>"processingComment")
      }

      t.item_source(:path=>"itemSource") {
        t.ingest_origin(:path=>"ingestOrigin")
        t.ingest_filepath(:path=>"ingestFilepath") #Only supported later for file objects.
        t.ingest_filename(:path=>"ingestFilename") #Only recently added
      }

      t.item_ark_info(:path=>"arkInformation") {
        t.ark_id(:path=>"arkID")
        t.ark_type(:path=>"arkType")
        t.ark_parent_pid(:path=>"arkParentPID")
      }

      t.source(:path=>"source") {
        t.ingest_origin(:path=>"ingestOrigin")
        t.ingest_filepath(:path=>"ingestFilepath") #Only supported later for file objects.
        t.ingest_filename(:path=>"ingestFilename") #Only recently added
        t.ingest_datastream(:path=>"ingestDatastream")
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

    def insert_file_source(filepath, filename, datastream)
      source_count = self.source.count

      self.source(source_count).ingest_filepath(0, filepath) unless filepath.blank?
      self.source(source_count).ingest_filename(0, filename) unless filename.blank?
      self.source(source_count).ingest_datastream(0, datastream) unless datastream.blank?
    end

    def insert_flagged(value=nil)
      self.item_designations(0).flagged_for_content(0, value) unless value.blank?
    end

    def insert_oai_defaults
      @object.workflowMetadata.item_status(0).state = "published"
      @object.workflowMetadata.item_status(0).state_comment = "OAI Harvested Record"
      @object.workflowMetadata.item_status(0).processing = "complete"
      @object.workflowMetadata.item_status(0).processing_comment = "Object Processing Complete"
    end
  end
end