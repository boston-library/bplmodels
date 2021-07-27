module Bplmodels
  module DatastreamExport
    extend ActiveSupport::Concern

    included do

      def filestreams_for_export(datastreams_for_export, fs_type = nil, include_foxml = true)
        @file_set_type = fs_type if fs_type.present?
        datastream_hashes = []
        @file_source_data = file_source_data
        datastreams_for_export.each do |ds|
          datastream = datastreams[ds]

          # if JP2 is both productionMaster and accessMaster, remove productionMaster
          next if ds == 'productionMaster' && datastream.mimeType == 'image/jp2'

          # if DocumentFile with duplicate of productionMaster and ocrMaster
          next if @file_set_type == 'document' && ds == 'productionMaster' &&
                  datastream.mimeType == 'text/plain' && datastreams['ocrMaster'].present? &&
                  datastream.size == datastreams['ocrMaster'].size

          next unless datastream.present?

          # calculate checksum if doesn't exist (should only be a problem in Test Fedora)
          checksum = if datastream.checksum == 'none' || datastream.checksum.blank?
                       ds_content = datastream.content
                       if ds_content.is_a?(String)
                         Digest::MD5.hexdigest(ds_content)
                       elsif ds_content.is_a?(RestClient::Response)
                         Digest::MD5.hexdigest(ds_content.body)
                       end
                     else
                       datastream.checksum
                     end
          #created = datastream.createDate&.strftime('%Y-%m-%dT%T.%LZ')
          file_hash = {
            file_name: filename_for_datastream(datastream),
            #created_at: created,
            #updated_at: (datastream.lastModifiedDate&.strftime('%Y-%m-%dT%T.%LZ') || created),
            file_type: attachment_type_for_dsid(ds, datastream.mimeType),
            content_type: datastream.mimeType,
            byte_size: datastream.size,
            checksum_md5: checksum,
            metadata: metadata_for_datastream(datastream),
            #filestream_of: {
            #  ark_id: pid,
            #  file_set_type: @file_set_type
            #},
            io: {
              fedora_content_location: "#{FEDORA_URL['url']}/objects/#{pid}/datastreams/#{ds}/content"
            }
          }
          file_hash[:key] = key_for_datastream(datastream) if parent_pid
          datastream_hashes << file_hash.compact
        end
        datastream_hashes << foxml_hash if include_foxml
        #{ files: datastream_hashes }
        datastream_hashes
      end

      def filename_for_datastream(datastream)
        ds_id = datastream.dsid

        if @file_source_data[ds_id] && @file_source_data[ds_id][:ingest_filename]
          @file_source_data[ds_id][:ingest_filename]
        else
          att_type = attachment_type_for_dsid(ds_id, datastream.mimeType)
          extension = filename_extension(datastream.mimeType)
          "#{att_type}.#{extension}"
        end
      end

      def key_for_datastream(datastream)
        ds_id = datastream.dsid
        extension = filename_extension(datastream.mimeType)
        att_type = attachment_type_for_dsid(ds_id, datastream.mimeType)
        "#{@file_set_type.pluralize}/#{parent_pid}/#{att_type}.#{extension}"
      end

      def parent_pid
        return object_id if @file_set_type == 'institution'

        return nil if [self.class.superclass, self.class.superclass&.superclass].include?(Bplmodels::ObjectBase)

        pid
      end

      def attachment_type_for_dsid(legacy_dsid, mime_type)
        file_type = filename_extension(mime_type)
        if legacy_dsid == 'productionMaster'
          case file_type
          when 'tif', 'jpg', 'png'
            'image_primary'
          when 'doc'
            'document_primary'
          when 'pdf'
            'document_access'
          when 'wav'
            'audio_primary'
          when 'mp3'
            'audio_access'
          when 'epub'
            'ebook_access_epub'
          when 'mobi'
            'ebook_access_mobi'
          when 'zip'
            'ebook_access_daisy'
          when 'mov'
            'video_primary'
          end
        elsif self.class == Bplmodels::VideoFile && legacy_dsid == 'accessMaster'
          'video_access_mp4'
        else
          attachment_type_for_nonmaster_dsid(legacy_dsid, file_type)
        end
      end

      def attachment_type_for_nonmaster_dsid(legacy_dsid, file_type)
        # edge case where PDF DocumentFiles sometimes have Word doc as preProductionNegativeMaster
        if legacy_dsid == 'preProductionNegativeMaster' &&
           (file_type == 'application/msword' || file_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
          'document_primary'
        else
          case legacy_dsid
          when 'preProductionNegativeMaster'
            'image_negative_primary'
          when 'ocrMaster', 'plainText'
            'text_plain'
          when 'djvuXML'
            'text_coordinates_primary'
          when 'djvuCoords'
            'text_coordinates_access'
          when 'accessMaster'
            'image_service'
          when 'access800'
            'image_access_800'
          when 'thumbnail300'
            'image_thumbnail_300'
          when 'characterization'
            legacy_dsid
          when 'georectifiedMaster'
            'image_georectified_primary'
          when 'oaiMetadata'
            'metadata_oai'
          when 'marcXML'
            'metadata_marc_xml'
          when 'iaMeta'
            'metadata_ia'
          when 'scanData'
            'metadata_ia_scan'
          when 'descMetadata'
            'metadata_mods'
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
        when 'application/msword'
          'doc'
        when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          'docx'
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
        file_hash = {
          file_name: "metadata_foxml.xml",
          file_type: 'metadata_foxml',
          content_type: 'application/xml',
          byte_size: foxml_string.bytesize,
          checksum_md5: Digest::MD5.hexdigest(foxml_string),
          io: { fedora_content_location: foxml_resp.request.url }
        }
        file_hash[:key] = "#{@file_set_type.pluralize}/#{parent_pid}/metadata_foxml.xml" if parent_pid
        file_hash
      end
    end
  end
end
