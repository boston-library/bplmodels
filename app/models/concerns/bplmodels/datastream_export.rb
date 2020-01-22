module Bplmodels
  module DatastreamExport
    extend ActiveSupport::Concern
    included do

      # if JP2 is both productionMaster and accessMaster, remove dupe and modify
      def files_for_export(datastreams_for_export, include_foxml = true)
        jp2_master = false
        datastream_hashes = []
        @file_source_data = file_source_data
        datastreams_for_export.each do |ds|
          next if ds == 'accessMaster' && jp2_master == true
          datastream = datastreams[ds]
          if datastream.present?
            checksum = datastream.checksum
            jp2_master = true if ds == 'productionMaster' && datastream.mimeType == 'image/jp2'
            created = datastream.createDate&.strftime('%Y-%m-%dT%T.%LZ')
            file_hash = {
              file_name: filename_for_datastream(datastream, datastreams["productionMaster"]&.label),
              created_at: created,
              updated_at: (datastream.lastModifiedDate&.strftime('%Y-%m-%dT%T.%LZ') || created),
              file_type: type_for_dsid(ds, datastream.mimeType),
              content_type: datastream.mimeType,
              byte_size: datastream.size,
              checksum: (checksum == 'none' || checksum.blank? ? nil : checksum),
              metadata: metadata_for_datastream(datastream),
              filestream_of: { ark_id: pid },
              fedora_content_location: "#{FEDORA_URL['url']}/objects/#{pid}/#{ds}/content"
            }
            datastream_hashes << { file: file_hash.compact }
          end
        end
        datastream_hashes << { file: foxml_hash } if include_foxml
        { files: datastream_hashes }
      end

      # TODO: test this, especially with IA stuff (djvuXML, djvuCoords, plainText etc)
      def filename_for_datastream(datastream, label = nil)
        ds_id = datastream.dsid
        #if ds_id =~ /Master\z/ && ds_id != 'accessMaster'
        if @file_source_data[ds_id] && @file_source_data[ds_id][:ingest_filename]
          puts "@file_source_data = #{@file_source_data}"
          puts "ds_id = #{ds_id}"
          @file_source_data[ds_id][:ingest_filename]
        else
          new_type = type_for_dsid(ds_id, datastream.mimeType)
          "#{(label || pid.gsub(/:/, '_'))}_#{new_type}.#{filename_extension(datastream.mimeType)}"
        end
      end

      def type_for_dsid(legacy_dsid, mime_type)
        file_type = filename_extension(mime_type)
        if legacy_dsid == 'productionMaster'
          case file_type
          when 'tif', 'jpg', 'png', 'jp2'
            'ImageMaster'
          when 'doc', 'pdf'
            'DocumentMaster'
          when 'wav', 'mp3'
            'AudioMaster'
          when 'epub', 'mobi', 'zip'
            'EbookAccess'
          when 'mov'
            'VideoMaster'
          end
        elsif self.class == Bplmodels::VideoFile && file_type == 'access800'
          'VideoAccess'
        else
          case legacy_dsid
          when 'preProductionNegativeMaster'
            'ImageNegativeMaster'
          when 'ocrMaster', 'plainText'
            'TextPlain'
          when 'djvuXML'
            'TextCoordinatesMaster'
          when 'djvuCoords'
            'TextCoordinatesAccess'
          when 'accessMaster'
            'ImageService'
          when 'access800'
            'ImageAccess800'
          when 'thumbnail300'
            'ImageThumbnail300'
          when 'characterization'
            legacy_dsid.capitalize
          when 'georectifiedMaster'
            'ImageGeorectifiedMaster'
          when 'oaiMetadata'
            'MetadataOAI'
          when 'marcXML'
            'MetadataMARCXML'
          when 'iaMeta'
            'MetadataIA'
          when 'scanData'
            'MetadataIAScan'
          when 'descMetadata'
            'MetadataMODS'
          else
            raise Error
          end
        end
      end

      def filename_extension(mime_type)
        case mime_type
        when 'image/tiff'
          'tif'
        when 'image/jp2'
          'jp2'
        when 'image/jpeg'
          'jpg'
        when 'application/xml', 'text/xml'
          'xml'
        when 'text/plain'
          'txt'
        when 'application/json'
          'json'
        when 'application/pdf'
          'pdf'
        when 'audio/mpeg'
          'mp3'
        when 'application/epub+zip'
          'epub'
        when 'application/x-mobipocket-ebook'
          'mobi'
        when 'application/zip'
          'zip'
        when 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          'doc'
        when 'audio/x-wav'
          'wav'
        when 'image/png'
          'png'
        when 'video/quicktime'
          'mov'
        when 'video/mp4'
          'mp4'
        else
          raise Error
        end
      end

      def file_source_data
        filesources = {}
        workflowMetadata.source.each_with_index do |_source, index|
          filesources[workflowMetadata.source.ingest_datastream[index]] = {
            ingest_filename: workflowMetadata.source.ingest_filename[index],
            ingest_filepath: workflowMetadata.source.ingest_filepath[index]
          }
        end
        filesources
      end

      def filepath_for_datastream(datastream)
        ds_id = datastream.dsid
        return nil unless ds_id =~ /Master\z/ && ds_id != 'accessMaster'
        @file_source_data[ds_id][:ingest_filepath]
      end

      def metadata_for_datastream(datastream)
        metadata = {}
        metadata['ingest_filepath'] = filepath_for_datastream(datastream)
        if datastream.dsid == 'productionMaster' && self.class == Bplmodels::ImageFile
          metadata['height'] = height&.first
          metadata['width'] = width&.first
        end
        metadata.compact!
        metadata.present? ? metadata : nil
      end

      def foxml_hash
        repo = ActiveFedora::Base.connection_for_pid(pid)
        fc3 = Rubydora::Fc3Service.new(repo.config)
        foxml_resp = fc3.export(pid: pid, format: 'info:fedora/fedora-system:FOXML-1.1', content: 'archive')
        foxml_string = foxml_resp.body
        {
          filename: "#{pid.gsub(/:/, '_')}_FOXML.xml",
          created_at: create_date,
          updated_at: modified_date,
          file_type: 'MetadataFOXML',
          mime_type: 'application/xml',
          size: foxml_string.bytesize,
          md5_checksum: Digest::MD5.hexdigest(foxml_string),
          filestream_of: {
            ark_id: pid
          },
          fedora_content_location: foxml_resp.request.url
        }
      end
    end
  end
end
