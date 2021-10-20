module Bplmodels
  module DigitalObjectExport
    extend ActiveSupport::Concern
    included do
      include Bplmodels::DescMetadataExport

      def export_to_curator(include_files = true)
        exp = Bplmodels::CuratorExportService.new(payload: export_data_for_curator_api)
        puts "exporting #{self.class} with id: #{pid}"
        result = { success: exp.export }
        if include_files && result[:success]
          export_filesets_to_curator
        else
          result
        end
      end

      def export_filesets_to_curator
        result = { success: false }
        total_bytes = 0
        total_filesets = 0
        total_blobs = 0
        filesets_for_export.each do |fs_for_export|
          # have to check if [:files] is set; #filesets_for_export doesn't return all the data we need
          if fs_for_export[:file_set][:files].blank?
            f = Bplmodels::File.find(fs_for_export[:file_set][:ark_id])
            fs_for_export[:file_set][:files] = f.export_filestreams_for_curator_api(true)
          end
          exp = Bplmodels::CuratorExportService.new(payload: fs_for_export)
          puts "exporting #{fs_for_export[:file_set][:file_set_type]} fileset with id: #{fs_for_export[:file_set][:ark_id]}"
          result[:success] = exp.export
          total_filesets += 1
          total_blobs += fs_for_export[:file_set][:files].count
          total_bytes += fs_for_export[:file_set][:files].map { |f| f[:byte_size] }.sum
        end
        result[:total_bytes] = total_bytes
        result[:total_filesets] = total_filesets
        result[:total_blobs] = total_blobs
        result
      end

      # exports DigitalObject
      def export_data_for_curator_api # (include_filesets = true)
        return nil if is_volume_wrapper?
        export = {}
        export[:ark_id] = pid
        export[:created_at] = create_date
        export[:updated_at] = modified_date
        export[:admin_set] = { ark_id: admin_set.pid } # name: admin_set.label
        export[:is_member_of_collection] = collection.map { |col| { ark_id: col.pid } } # name: col.label

        export[:metastreams] = {}
        export[:metastreams][:descriptive] = desc_metadata_for_export_hash
        export[:metastreams][:administrative] = {
          description_standard: desc_std_for_admin,
          flagged: workflowMetadata.item_designations(0).flagged_for_content[0],
          destination_site: workflowMetadata.destination.site,
          harvestable: if workflowMetadata.item_status.harvestable[0] =~ /[Ff]alse/ ||
              workflowMetadata.item_status.harvestable[0] == false
                         false
                       else
                         true
                       end,
          hosting_status: self.class == Bplmodels::OAIObject ? 'harvested' : 'hosted',
          oai_header_id: self.class == Bplmodels::OAIObject ? oaiMetadata.header_information.identifer[0]&.strip : nil,
          access_edit_group: rightsMetadata.access(2).machine.group
        }.compact
        export[:metastreams][:workflow] = {
          ingest_origin: ingest_origin_for_workflow,
          processing_state: workflowMetadata.item_status.processing[0],
          publishing_state: workflowMetadata.item_status.state[0]
        }.compact

        { digital_object: export.compact }
      end

      def desc_metadata_for_export_hash
        related_items = related_items_for_export_hash
        physical_location = physical_location_for_export_hash
        rights = rights_for_export_hash
        descriptive_metadata = {
          identifier: identifiers_for_export_hash,
          title: titles_for_export_hash,
          name_roles: names_for_export_hash,
          resource_types: rt_for_export_hash,
          resource_type_manuscript: (descMetadata.mods(0).type_of_resource.manuscript.first == 'yes' ? true : nil),
          genres: genres_for_export_hash,
          digital_origin: descMetadata.mods(0).physical_description.digital_origin[0].presence&.parameterize(separator: '_'),
          origin_event: descMetadata.mods(0).origin_info.event_type[0].presence,
          place_of_publication: descMetadata.mods(0).origin_info.place.place_term[0].presence&.gsub(/\|\|/, ' ; '),
          publisher: descMetadata.mods(0).origin_info.publisher[0].presence&.gsub(/\|\|/, ' ; '),
          date: dates_for_export_hash,
          publication: {
            edition_name: descMetadata.mods(0).origin_info.edition[0].presence
          }.compact,
          issuance: descMetadata.mods(0).origin_info.issuance[0].presence,
          frequency: descMetadata.mods(0).origin_info.frequency[0].presence,
          languages: langs_for_export_hash,
          note: notes_for_export_hash,
          extent: descMetadata.mods(0).physical_description(0).extent.join(' '),
          text_direction: td_for_export_hash,
          abstract: descMetadata.mods(0).abstract.join('<br/><br/>'),
          toc: descMetadata.mods(0).table_of_contents.join(' '),
          toc_url: descMetadata.mods(0).table_of_contents.href[0].presence,
          subject: subjects_for_export_hash,
          cartographic: {
            scale: descMetadata.mods(0).subject.cartographics.scale.presence,
            projection: descMetadata.mods(0).subject.cartographics.projection[0].presence
          }.compact,
          host_collections: related_items[:host],
          series: related_items[:series],
          subseries: related_items[:subseries],
          subsubseries: related_items[:subsubseries],
          related: {
            referenced_by: related_items[:referenced_by],
            constituent: related_items[:constituent]
          }.compact,
          physical_location: { label: physical_location[:label], name_type: 'corporate' },
          physical_location_department: physical_location[:department],
          physical_location_shelf_locator: physical_location[:shelf_locator],
          rights: rights[:rights],
          license: rights[:license],
          rights_statement: rights[:rights_statement],
          access_restrictions: descMetadata.mods(0).restriction_on_access[0].presence
        }
        descriptive_metadata.compact.reject { |_k, v| v.blank? }
      end

      # if this is a volume in series, add the relationship
      def find_issues_for_volume
        issue_ids = []
        relationships.each_statement do |statement|
          if statement.predicate =~ /isVolumeOf/
            issue_ids << statement.object.to_s.gsub(/info:fedora\//,'')
          end
        end
        issue_ids.map { |v| { ark_id: v } } unless issue_ids.blank?
      end

      # the object returned is too large in certain cases (items with 900+ pages)
      # so we don't include all the file/attachment data for "normal" (non-Ereader) Bplmodels::File objects
      # upstream methods will have to call #export_data_for_curator_api(true) to get
      # the export has with files included.
      def filesets_for_export(include_files = true)
        filesets = []
        has_ereader_files = false
        # get file-level filesets (image, document, video, etc); remove ereader (do 'em separately)
        all_files = Bplmodels::Finder.getFiles(pid)
        all_files.delete(:ereader)
        ## all_files.delete(:images) # uncomment for easier testing of IA objects
        all_files.each_value do |files_array|
          filesets.concat filesets_for_files(files_array, false)
        end
        # get EReader filesets and combine, make EPub the 'primary'
        ereader_files = Bplmodels::Finder.getEreaderFiles(pid)
        if ereader_files.present?
          has_ereader_files = true
          ereader_fileset_for_export = nil
          if include_files
            ereader_filesets = filesets_for_files(ereader_files, include_files)
            ereader_filesets.each_with_index do |er_fileset, index|
              if er_fileset[:file_set][:files][0][:content_type] == 'application/epub+zip'
                ereader_fileset_for_export = er_fileset
                ereader_filesets.delete_at(index)
              end
            end
            ereader_filesets.each do |er_fileset|
              er_fileset[:file_set][:files].each do |er_file|
                next unless er_file[:file_type].match?(/ebook_access/)

                ereader_fileset_for_export[:file_set][:files] << er_file
              end
            end
          else
            ereader_files = ereader_files.select { |erf| erf["mime_type_tesim"].include?("application/epub+zip") }
            if ereader_files.present?
              ereader_fileset_obj = Bplmodels::File.find(ereader_files.first['id'])
              ereader_fileset_for_export = ereader_fileset_obj.export_data_for_curator_api(include_files)
            end
          end
          filesets << ereader_fileset_for_export
        end
        # have to modify keys of ebook_access_mobi and ebook_access_daisy files to use epub pid
        if has_ereader_files
          filesets.each do |fs|
            fileset = fs[:file_set]
            next unless fileset[:file_set_type] == 'ereader'

            pid_for_key = fileset[:ark_id]
            fileset[:files].each do |file|
              if file[:file_type] == 'ebook_access_daisy' || file[:file_type] == 'ebook_access_mobi'
                key_parts = file[:key].split('/')
                key_parts[1] = pid_for_key if key_parts[1].match?(/[\w-]*:[0-9a-z]*/)
                file[:key] = key_parts.join('/')
              end
            end
          end
        end
        # get the object-level filesets (metadata, plainText, etc)
        object_filesets = object_filesets_for_export(object_filestreams_for_export)
        filesets + object_filesets
      end

      def filesets_for_files(files_array, include_files = true)
        filesets = []
        files_array.each do |file_doc|
          fileset_obj = Bplmodels::File.find(file_doc['id'])
          fileset_hash = fileset_obj.export_data_for_curator_api(include_files)
          filesets << fileset_hash
        end
        filesets
      end

      def object_filestreams_for_export
        @file_set_type = nil # value will be set in #object_filesets_for_export
        { metadata: filestreams_for_export(%w[oaiMetadata descMetadata marcXML iaMeta scanData thumbnail300],
                                           'metadata'),
          text: filestreams_for_export(%w[plainText djvuXML], 'text', false) }
      end

      # get the object-level files -- metadata, full text, IA data, etc
      def object_filesets_for_export(object_files, include_files = true)
        object_filesets = []
        %w[metadata text].each do |fileset_type|
          next if object_files[fileset_type.to_sym].blank?
          object_fileset = {
            created_at: create_date,
            updated_at: modified_date,
            file_set_of: { ark_id: pid },
            file_set_type: fileset_type,
            file_name_base: "#{pid}_#{fileset_type}",
            metastreams: {
              administrative: { access_edit_group: rightsMetadata.access(2).machine.group },
              workflow: {
                ingest_origin: ingest_origin_for_workflow,
                processing_state: workflowMetadata.item_status.state[0] == 'published' ? 'complete' : 'derivatives'
              }.compact
            }
          }
          exemplary_ids = []
          relationships.each_statement do |statement|
            if statement.predicate =~ /isExemplaryImageOf/
              exemplary_ids << statement.object.to_s.gsub(/info:fedora\//,'')
            end
          end
          unless exemplary_ids.blank?
            object_fileset[:exemplary_image_of] = []
            exemplary_ids.uniq.each do |pid|
              object_fileset[:exemplary_image_of] << { ark_id: pid }
            end
          end
          object_fileset[:files] = object_files[fileset_type.to_sym] if include_files
          object_filesets << { file_set: object_fileset }
        end
        object_filesets
      end

      def ingest_origin_for_workflow
        if self.class == Bplmodels::OAIObject
          oaiMetadata.header_information.identifer.first&.strip
        elsif workflowMetadata.source.present? &&
            workflowMetadata.source.ingest_filepath[0] =~ /archive.org/
          workflowMetadata.source.ingest_filepath[0].gsub(/\/[a-z\.0-9_]*\z/, '')
        else
          'spreadsheet'
        end
      end

      # if this is a wrapper object for Book/Volume, skip it
      # volume stuff from DC2 is deprecated (and there are only 2 of these anyway)
      def is_volume_wrapper?
        volumes = Bplmodels::Finder.getVolumeObjects(pid)
        volumes.present? ? true : false
      end

      def desc_std_for_admin
        ds_value = descMetadata.mods(0).record_info.description_standard[0]
        allowed = ["aacr", "cco", "dacs", "gihc", "local", "rda", "dcrmg", "amremm",
                   "dcrmb", "dcrmc", "dcrmmss", "appm"]
        allowed.include?(ds_value) ? ds_value : nil
      end
    end
  end
end
