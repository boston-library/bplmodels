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

    has_file_datastream 'access800', versionable: false,  label:'access800 datastream'

    has_file_datastream 'ocrMaster', versionable: false,  label:'OCR master datastream'
    has_file_datastream 'djvuCoords', versionable: false,  label:'djvu coordinate json datastream'


    belongs_to :object, :class_name => "Bplmodels::ObjectBase", :property => :is_image_of

    belongs_to :exemplary, :class_name => "Bplmodels::ObjectBase", :property => :is_exemplary_image_of

    # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    has_metadata :name => "ARCHV-EXIF", :type => ActiveFedora::Datastream, :label=>'Archive image EXIF metadata'

    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    has_metadata :name => "pageMetadata", :type => PageMetadata

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

      if ['image/tiff', 'image/png', 'image/jpg', 'image/jp2'].include?(self.productionMaster.mimeType) and self.accessMaster.blank?
        doc['derivative_processsed_ssi'] = 'false'
      else
        doc['derivative_processsed_ssi'] = 'true'
      end

      if self.pageMetadata.present?
        doc['page_type_ssi'] = self.pageMetadata.pageData.page.page_type.first
        doc['hand_side_ssi'] = self.pageMetadata.pageData.page.hand_side.first
        doc['page_num_label_ssi'] = self.pageMetadata.pageData.page.page_number.first if self.pageMetadata.pageData.page.page_number.present?
        doc['page_num_label_type_ssi'] = self.pageMetadata.pageData.page.page_number.sequence.first if self.pageMetadata.pageData.page.page_number.present?
        #doc['has_ocr_master_ssi'] = self.bookMetadata.book.page_data.page.has_ocrMaster.first
        #doc['has_djvu_json_ssi'] = self.bookMetadata.book.page_data.page.has_djvu.first

        if self.ocrMaster.present?
          doc['ocr_tsiv'] = self.ocrMaster.content.squish
        end

        if self.djvuCoords.present?
          doc['has_djvu_json_ssi'] = 'true'
        end
      end

      doc['checksum_file_md5_ssi'] = self.productionMaster.checksum

      doc

    end

    def generate_derivatives
      #Sample object on prod: https://fedora.digitalcommonwealth.org/fedora/objects/commonwealth:9w032896b/datastreams/productionMaster/content
      #Sample object from test book object: https://fedoratest.bpl.org/fedora/objects/bpl-test:rf55zp77f/datastreams/productionMaster/content
      case self.productionMaster.mimeType
        when 'application/pdf'
          #transform_datastream :productionMaster, { :thumb => "100x100>" }

          pdffile = Tempfile.new(['derivative','.pdf'])
          pdffile.binmode
          pdffile.write(self.productionMaster.content) #ActiveFedora.config.credentials[:url] + '/objects/' + self.pid + '/datastreams/productionMaster/content'
          pdffile.close

          current_page = 0
          total_colors = 0
          until total_colors > 1 do
            #Won't work... asks for login with the brackets...
            img = Magick::Image.read(pdffile.path + '[' + current_page.to_s + ']'){
              self.quality = 100
              self.density = 200
            }.first
            total_colors = img.total_colors
            current_page = current_page + 1
          end

          #This is horrible. But if you don't do this, some PDF files won't come out right at all.
          #Multiple attempts have failed to fix this but perhaps the bug will be patched in ImageMagick.
          #To duplicate, one can use the PDF files at: http://libspace.uml.edu/omeka/files/original/7ecb4dc9579b11e2b53ccc2040e58d36.pdf
          img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

          thumb = img.resize_to_fit(300,300)

          self.thumbnail300.content = thumb.to_blob { self.format = "jpg" }
          self.thumbnail300.mimeType = 'image/jpeg'
          self.thumbnail300.dsLabel = self.productionMaster.label

          pdffile.delete
        when 'audio/wav'
          #transform_datastream :productionMaster, { :mp3 => {format: 'mp3'}, :ogg => {format: 'ogg'} }, processor: :audio
        when 'video/avi'
          #transform_datastream :productionMaster, { :mp4 => {format: 'mp4'}, :webm => {format: 'webm'} }, processor: :video
        when 'image/tiff', 'image/png', 'image/jpg'
          begin
            transform_datastream :productionMaster, { :testJP2k => { recipe: :default, datastream: 'accessMaster'  } }, processor: 'jpeg2k_image'
          rescue => error
            if error.message.include?('compressed TIFF files')
              #Magick::limit_resource(:memory, 8500000000)
              #Magick::limit_resource(:map, 8500000000)
              #jp2_img =  Magick::Image.read("#{self.fedora_connection[0].options[:url]}/objects/#{self.pid}datastreams/productionMaster/content").first
=begin
              jp2_img =  Magick::Image.from_blob(self.productionMaster.content).first
              self.accessMaster.content = jp2_img.to_blob { self.format = "jp2" }
              self.accessMaster.mimeType = 'image/jp2'
              jp2_img.destroy!
=end
              jp2_img = MiniMagick::Image.read(self.productionMaster.content) do |b|
                b.format "jp2"
              end

              self.accessMaster.content = jp2_img.to_blob
              self.accessMaster.mimeType = 'image/jp2'
              jp2_img.destroy!
            else
              raise error
            end
          end
          transform_datastream :productionMaster, { :thumb => {size: "300x300>", datastream: 'thumbnail300', format: 'jpg'} }
          transform_datastream :productionMaster, { :thumb => {size: "x800>", datastream: 'access800', format: 'jpg'} }
          self.accessMaster.dsLabel = self.productionMaster.label
          self.thumbnail300.dsLabel = self.productionMaster.label
          self.access800.dsLabel = self.productionMaster.label
        when 'image/jpeg' #FIXME
          #Magick::limit_resource(:memory, 5500000000)
          #Magick::limit_resource(:map, 5500000000)
=begin
          iajp2file = Tempfile.new(['iajp2file','.jp2'])
          iajp2file.write(entry.get_input_stream.read)
          iajp2file.close
=end

=begin
          jp2_img =  Magick::Image.from_blob(self.productionMaster.content).first
          self.accessMaster.content = jp2_img.to_blob { self.format = "jp2" }
          self.accessMaster.mimeType = 'image/jp2'
          jp2_img.destroy!
=end

          jp2_img = MiniMagick::Image.read(self.productionMaster.content) do |b|
            b.format "jp2"
          end

          self.accessMaster.content = jp2_img.to_blob
          self.accessMaster.mimeType = 'image/jp2'
          jp2_img.destroy!

          transform_datastream :productionMaster, { :thumb => {size: "300x300>", datastream: 'thumbnail300', format: 'jpg'} }
          transform_datastream :productionMaster, { :thumb => {size: "x800>", datastream: 'access800', format: 'jpg'} }
          self.accessMaster.dsLabel = self.productionMaster.label
          self.thumbnail300.dsLabel = self.productionMaster.label
          self.access800.dsLabel = self.productionMaster.label
        when 'image/jp2'
          self.accessMaster.content = self.productionMaster.content
          self.accessMaster.mimeType = 'image/jp2'


=begin
          source_path = "#{ActiveFedora.config.credentials[:url]}/#{self.productionMaster.url}"
          image = MiniMagick::Image.open(source_path)
          quality = image['%[channels]'] == 'gray' ? 'gray' : 'color'
          long_dim = Hydra::Derivatives::Jpeg2kImage.long_dim(image)
          directives = { recipe: :default, datastream: 'accessMaster'  }
          recipe = Hydra::Derivatives::Jpeg2kImage.kdu_compress_recipe(directives, quality, long_dim)

          file_path = Hydra::Derivatives::Jpeg2kImage.tmp_file('.jp2')
          image.write file_path


          output_file = Hydra::Derivatives::Jpeg2kImage.tmp_file('.jp2')
          Hydra::Derivatives::Jpeg2kImage.encode(file_path, recipe, output_file)
          self.accessMaster.content = ::File.open(output_file)
          self.accessMaster.mimeType = 'image/jp2'
          #End wonky code

          #TODO: Move this to a function in Hydra Derivatives...
          self.save
          image.destroy!
          File.unlink(output_file)
          File.unlink(file_path)
=end

          transform_datastream :productionMaster, { :thumb => {size: "300x300>", datastream: 'thumbnail300', format: 'jpg'} }
          transform_datastream :productionMaster, { :thumb => {size: "x800>", datastream: 'access800', format: 'jpg'} }
          self.accessMaster.dsLabel = self.productionMaster.label
          self.thumbnail300.dsLabel = self.productionMaster.label
          self.access800.dsLabel = self.productionMaster.label


      end

    end

    def derivative_service(is_new)
      response = Typhoeus::Request.post(DERIVATIVE_CONFIG_GLOBAL['url'] + "/processor/byfile.json", :params => {:pid=>self.pid, :new=>is_new, :environment=>Bplmodels.environment})
      puts response.body.to_s
      as_json = JSON.parse(response.body)

      if as_json['result'] == "false"
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
      begin
        as_json = JSON.parse(response.body)
      rescue => ex
        raise('Error in JSON response for minting a file pid.')
      end

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