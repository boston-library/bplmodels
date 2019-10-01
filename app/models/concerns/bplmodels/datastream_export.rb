module Bplmodels
  module DatastreamExport
    extend ActiveSupport::Concern
    included do

      # if JP2 is both productionMaster and accessMaster, remove dupe and modify
      def files_for_export(datastreams_for_export, include_foxml = true)
        jp2_master = false
        datastream_hashes = []
        datastreams_for_export.each do |ds|
          next if ds == 'accessMaster' && jp2_master = true
          datastream = datastreams[ds]
          if datastream.present?
            jp2_master = true if ds == 'productionMaster' && datastream.mimeType == 'image/jp2'
            created = datastream.createDate&.strftime('%Y-%m-%dT%T.%LZ')
            file_hash = {
              filename: filename_for_datastream(datastream, datastreams["productionMaster"]&.label),
              created_at: created,
              updated_at: (datastream.lastModifiedDate&.strftime('%Y-%m-%dT%T.%LZ') || created),
              file_type: [type_for_dsid(ds, datastream.mimeType)],
              mime_type: datastream.mimeType,
              size: datastream.size,
              md5_checksum: datastream.checksum,
              filestream_of: { ark_id: pid }
            }
            datastream_hashes << { file: file_hash }
          end
        end
        datastream_hashes << { file: foxml_hash } if include_foxml
        { files: datastream_hashes }
      end

      def filename_for_datastream(datastream, label = nil)
        ds_id = datastream.dsid
        if ds_id == 'productionMaster'
          filename.first
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
          end
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
        else
          raise Error
        end
      end

      def foxml_hash
        repo =  ActiveFedora::Base.connection_for_pid(pid)
        fc3 = Rubydora::Fc3Service.new(repo.config)
        foxml_resp = fc3.export(pid: pid, format: 'info:fedora/fedora-system:FOXML-1.1', content: 'archive')
        foxml_string = foxml_resp.body
        {
          filename: "#{pid.gsub(/:/, '_')}_foxml.xml",
          created_at: create_date,
          updated_at: modified_date,
          type: 'MetadataFOXML',
          mime_type: 'application/xml',
          size: foxml_string.bytesize,
          md5_checksum: Digest::MD5.hexdigest(foxml_string),
          filestream_of: {
            ark_id: pid
          }
        }
      end
    end
  end
end
