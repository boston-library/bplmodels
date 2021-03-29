module Bplmodels
  module DatastreamExport
    extend ActiveSupport::Concern

    included do
      # if JP2 is both productionMaster and accessMaster, remove productionMaster
      def filestreams_for_export(datastreams_for_export, include_foxml = true)
        datastream_hashes = []
        @file_source_data = file_source_data
        datastreams_for_export.each do |ds|
          datastream = datastreams[ds]
          next if ds == 'productionMaster' && datastream.mimeType == 'image/jp2'

          next unless datastream.present?

          checksum = datastream.checksum
          #created = datastream.createDate&.strftime('%Y-%m-%dT%T.%LZ')
          file_hash = {
            file_name: filename_for_datastream(datastream, datastreams["productionMaster"]&.label),
            #created_at: created,
            #updated_at: (datastream.lastModifiedDate&.strftime('%Y-%m-%dT%T.%LZ') || created),
            file_type: type_for_dsid(ds, datastream.mimeType),
            content_type: datastream.mimeType,
            byte_size: datastream.size,
            checksum: ((checksum == 'none' || checksum.blank?) ? nil : checksum),
            metadata: metadata_for_datastream(datastream),
            #filestream_of: {
            #  ark_id: pid,
            #  file_set_type: @file_set_type
            #},
            io: {
              fedora_content_location: "#{FEDORA_URL['url']}/objects/#{pid}/datastreams/#{ds}/content"
            }
          }
          datastream_hashes << file_hash.compact
        end
        datastream_hashes << foxml_hash if include_foxml
        #{ files: datastream_hashes }
        datastream_hashes
      end

      def filename_for_datastream(datastream, label = nil)
        ds_id = datastream.dsid
        if @file_source_data[ds_id] && @file_source_data[ds_id][:ingest_filename]
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
          when 'tif', 'jpg', 'png'
            'ImageMaster'
          when 'doc', 'pdf'
            'DocumentMaster'
          when 'wav', 'mp3'
            'AudioMaster'
          when 'epub'
            'EbookAccessEpub'
          when 'mobi'
            'EbookAccessMobi'
          when 'zip'
            'EbookAccessDaisy'
          when 'mov'
            'VideoMaster'
          end
        elsif self.class == Bplmodels::VideoFile && legacy_dsid == 'accessMaster'
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
        if ds_id == 'thumbnail300' && self.class == Bplmodels::OAIObject
          return oaiMetadata.raw_info.file_urls.first
        end
        return nil unless @file_source_data[ds_id] && @file_source_data[ds_id][:ingest_filepath]
        @file_source_data[ds_id][:ingest_filepath]
      end

      def metadata_for_datastream(datastream)
        metadata = {}
        metadata['ingest_filepath'] = filepath_for_datastream(datastream)
        if datastream.dsid == 'productionMaster' && self.class == Bplmodels::ImageFile
          metadata['height'] = height&.first&.to_i
          metadata['width'] = width&.first&.to_i
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
          file_name: "#{pid.gsub(/:/, '_')}_FOXML.xml",
          # created_at: create_date,
          # updated_at: modified_date,
          file_type: 'MetadataFOXML',
          content_type: 'application/xml',
          byte_size: foxml_string.bytesize,
          checksum: Digest::MD5.hexdigest(foxml_string),
          #filestream_of: {
          #  ark_id: pid,
          #  file_set_type: @file_set_type
          #},
          io: { fedora_content_location: foxml_resp.request.url }
        }
      end
    end
  end
end
