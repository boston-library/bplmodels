module Bplmodels
  module DatastreamExport
    extend ActiveSupport::Concern
    included do

      def files_for_export(datastreams_for_export)
        datastream_hashes = []
        datastreams_for_export.each do |ds|
          datastream = datastreams[ds]
          if datastream.present?
            created = datastream.createDate&.strftime('%Y-%m-%dT%T.%LZ')
            file_hash = {
              filename: filename_for_datastream(datastream, datastreams["productionMaster"]&.label),
              created_at: created,
              updated_at: (datastream.lastModifiedDate&.strftime('%Y-%m-%dT%T.%LZ') || created),
              type: ds,
              mime_type: datastream.mimeType,
              size: datastream.size,
              md5_checksum: datastream.checksum,
              filestream_of: {
                ark_id: pid
              }
            }
            datastream_hashes << { file: file_hash }
          end
        end
        datastream_hashes << { file: foxml_hash }
        { files: datastream_hashes }
      end

      def filename_for_datastream(datastream, label = nil)
        ds_id = datastream.dsid
        if ds_id == 'productionMaster'
          filename.first
        else
          ds_id = 'wordCoords' if ds_id == 'djvuCoords'
          "#{(label || pid.gsub(/:/, '_'))}_#{ds_id}.#{filename_extension(datastream.mimeType)}"
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
          type: 'fedoraObjectXML',
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
