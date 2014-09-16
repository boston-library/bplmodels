module Bplmodels
  class File  < ActiveFedora::Base
    include Hydra::AccessControls::Permissions
    include Hydra::ModelMethods

    include Bplmodels::Characterization

    include ActiveFedora::Auditable
    include Hydra::Derivatives

    has_file_datastream 'preProductionNegativeMaster', versionable: true, label: 'preProductionNegativeMaster datastream'

    has_file_datastream 'productionMaster', versionable: true, label: 'productionMaster datastream', type: FileContentDatastream

    has_file_datastream 'accessMaster', versionable: false, label: 'accessMaster datastream'

    has_file_datastream 'thumbnail300', versionable: false,  label:'thumbnail300 datastream'

    belongs_to :object, :class_name => "Bplmodels::ObjectBase", :property => :is_image_of

    belongs_to :exemplary, :class_name => "Bplmodels::ObjectBase", :property => :is_exemplary_image_of

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    has_metadata :name => "ARCHV-EXIF", :type => ActiveFedora::Datastream, :label=>'Archive image EXIF metadata'

    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    def apply_default_permissions
      self.datastreams["rightsMetadata"].update_permissions( "group"=>{"Repository Administrators"=>"edit"} )
      self.save
    end

    def save
      self.add_relationship(:has_model, "info:fedora/afmodel:Bplmodels_File")
      super()
    end

    def to_solr(doc = {} )
      doc = super(doc)
      if self.workflowMetadata.marked_for_deletion.present?
        doc['marked_for_deletion_bsi']  =  self.workflowMetadata.marked_for_deletion.first
        doc['marked_for_deletion_reason_ssi']  =  self.workflowMetadata.marked_for_deletion.reason.first
      end

      doc

    end


    def generate_derivatives
      case self.productionMaster.mimeType
        when 'application/pdf'
          #transform_datastream :productionMaster, { :thumb => "100x100>" }
        when 'audio/wav'
          #transform_datastream :productionMaster, { :mp3 => {format: 'mp3'}, :ogg => {format: 'ogg'} }, processor: :audio
        when 'video/avi'
          #transform_datastream :productionMaster, { :mp4 => {format: 'mp4'}, :webm => {format: 'webm'} }, processor: :video
        when 'image/tiff', 'image/png', 'image/jpg'
          begin
            transform_datastream :productionMaster, { :testJP2k => { recipe: :default, datastream: 'accessMaster'  } }, processor: 'jpeg2k_image'
          rescue => error
            if error.message.include?('compressed TIFF files')
              Magick::limit_resource(:memory, 5500000000)
              Magick::limit_resource(:map, 5500000000)
              jp2_img =  Magick::Image.read("#{self.fedora_connection[0].options[:url]}/objects/#{self.pid}datastreams/productionMaster/content").first
              self.accessMaster.content = jp2_img.to_blob { self.format = "jp2" }
              self.accessMaster.mimeType = 'image/jpeg2000'
            else
              raise error
            end
          end
          transform_datastream :productionMaster, { :thumb => {size: "300x300>", datastream: 'thumbnail300', format: 'jpg'} }
          self.accessMaster.dsLabel = self.productionMaster.label
          self.thumbnail300.dsLabel = self.productionMaster.label
      end
    end

    def derivative_service(is_new)
      response = Typhoeus::Request.post(DERIVATIVE_CONFIG_GLOBAL['url'] + "/processor.json", :params => {:pid=>self.pid, :new=>is_new})
      as_json = JSON.parse(response.body)

      if as_json['result'] == "false"
        pid = self.object.pid
        self.delete
        raise "Error Generating Derivatives For Object: " + pid
      end

      return true
    end

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    #institution_pid => instituional access of this file
    def self.mint(args)

      #TODO: Duplication check here to prevent over-writes?

      args[:namespace_id] ||= ARK_CONFIG_GLOBAL['namespace_commonwealth_pid']

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:parent_pid=>args[:parent_pid], :namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>args[:namespace_id], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})
      as_json = JSON.parse(response.body)

      #Below stopped working suddenly?
=begin
      dup_check = ActiveFedora::Base.find(:pid=>as_json["pid"])
      if dup_check.present?
        return as_json["pid"]
      end
=end

      Bplmodels::File.find_in_batches('id'=>as_json["pid"]) do |group|
        group.each { |solr_result|
          return as_json["pid"]
        }
      end

      object = self.new(:pid=>as_json["pid"])

      object.label = args[:label]

      object.read_groups = ["public"]
      object.edit_groups = ["superuser", "admin[#{args[:institution_pid]}]"]  if args[:institution_pid].present?

      object.workflowMetadata.item_ark_info.ark_id = args[:local_id]
      object.workflowMetadata.item_ark_info.ark_type = args[:local_id_type]
      object.workflowMetadata.item_ark_info.ark_parent_pid = args[:parent_pid]

      return object
    end

  end
end