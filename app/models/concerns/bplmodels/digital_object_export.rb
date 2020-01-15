module Bplmodels
  module DigitalObjectExport
    extend ActiveSupport::Concern
    included do
      include Bplmodels::DescMetadataExport

      # TODO: check subsubseries export is working
      def export_for_bpl_api(include_filesets = true)
        return nil if is_volume_wrapper?
        export = {}
        export[:ark_id] = pid
        export[:created_at] = create_date
        export[:updated_at] = modified_date
        export[:admin_set] = {
          ark_id: admin_set.pid,
          name: admin_set.label
        }
        export[:is_member_of_collection] = collection.map { |col| { ark_id: col.pid, name: col.label } }
        # export[:is_issue_of] = find_issues_for_volume
        export[:metastreams] = {}
        export[:metastreams][:descriptve] = desc_metadata_for_export_hash
        export[:metastreams][:administrative] = {
          description_standard: descMetadata.mods(0).record_info.description_standard[0],
          flagged: (workflowMetadata.item_designations(0).flagged_for_content[0] == "true" ? true : false),
          destination_site: workflowMetadata.destination.site,
          harvestable: if workflowMetadata.item_status.harvestable[0] =~ /[Ff]alse/ ||
              workflowMetadata.item_status.harvestable[0] == false
                         false
                       else
                         true
                       end,
          access_edit_group: rightsMetadata.access(2).machine.group
        }.compact
        export[:metastreams][:workflow] = {
          processing_state: workflowMetadata.item_status.processing[0],
          publishing_state: workflowMetadata.item_status.state[0]
        }.compact
        export[:filesets] = filesets_for_export_hash if include_filesets
        { digital_object: export.compact }
      end

      def desc_metadata_for_export_hash
        titles = titles_for_export_hash
        related_items = related_items_for_export_hash
        physical_location = physical_location_for_export_hash
        rights = rights_for_export_hash
        descriptive_metadata = {
          identifier: identifiers_for_export_hash,
          title_primary: titles[:primary],
          title_other: titles[:other],
          name_roles: names_for_export_hash,
          resource_types: rt_for_export_hash,
          resource_type_manuscript: (descMetadata.mods(0).type_of_resource.manuscript.first == 'yes' ? true : nil),
          genres: genres_for_export_hash,
          digital_origin: descMetadata.mods(0).physical_description.digital_origin[0].presence,
          origin_event: descMetadata.mods(0).origin_info.event_type[0].presence,
          place_of_publication: descMetadata.mods(0).origin_info.place.place_term[0].presence,
          publisher: descMetadata.mods(0).origin_info.publisher[0].presence,
          date: dates_for_export_hash,
          edition_name: descMetadata.mods(0).origin_info.edition[0].presence,
          issuance: descMetadata.mods(0).origin_info.issuance[0].presence,
          frequency: descMetadata.mods(0).origin_info.frequency[0].presence,
          languages: langs_for_export_hash,
          note: notes_for_export_hash,
          extent: descMetadata.mods(0).physical_description(0).extent.join(' '),
          text_direction: td_for_export_hash,
          abstract: descMetadata.mods(0).abstract.join(' '),
          toc: descMetadata.mods(0).table_of_contents.join(' '),
          toc_url: descMetadata.mods(0).table_of_contents.href[0].presence,
          subject: subjects_for_export_hash,
          scale: descMetadata.mods(0).subject.cartographics.scale.presence,
          projection: descMetadata.mods(0).subject.cartographics.projection[0].presence,
          host_collections: related_items[:host],
          series: related_items[:series],
          subseries: related_items[:subseries],
          subsubseries: related_items[:subsubseries],
          related_referenced_by_url: related_items[:referenced_by_url],
          related_constituent: related_items[:constituent],
          physical_location: { label: physical_location[:label], name_type: 'corporate' },
          physical_location_department: physical_location[:department],
          physical_location_shelf_locator: physical_location[:shelf_locator],
          rights: rights[:rights],
          licenses: rights[:license],
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

      def filesets_for_export_hash(include_files = true)
        filesets = []
        # get file-level filesets (image, documemt, ereader, etc)
        all_files = Bplmodels::Finder.getFiles(pid)
        all_files.each_value do |files_array|
          files_array.each do |file_doc|
            fileset_obj = Bplmodels::File.find(file_doc['id'])
            fileset_hash = fileset_obj.export_fileset_for_bpl_api(include_files)
            filesets << fileset_hash
          end
        end
        # combine EReader filesets, make EPub the 'master'
        ereader_filesets = []
        filesets.each_with_index do |fileset, index|
          if fileset[:file_set][:fileset_type] == 'ereader'
            ereader_filesets << fileset
            filesets.delete_at(index)
          end
        end
        if ereader_filesets.present?
          ereader_fileset_for_export = nil
          ereader_filesets.each_with_index do |er_fileset, index|
            if er_fileset[:file_set][:files][0][:file][:mime_type] == 'application/epub+zip'
              ereader_fileset_for_export = er_fileset
              ereader_filesets.delete_at(index)
            end
          end
          ereader_filesets.each do |er_fileset|
            er_fileset[:file_set][:files].each do |er_file|
              if er_file[:file][:file_type] == 'EbookAccess'
                er_file[:file][:filestream_of][:ark_id] = ereader_fileset_for_export[:ark_id]
                ereader_fileset_for_export[:file_set][:files] << er_file
              end
            end
          end
          filesets << ereader_fileset_for_export
        end
        # get the object-level filesets (metadata, plainText, etc)
        object_filesets = object_filesets_for_export(object_files_for_export)
        filesets + object_filesets
      end

      def object_files_for_export
        { metadata: files_for_export(%w[oaiMetadata descMetadata marcXML iaMeta scanData]),
          image: files_for_export(['thumbnail300'], false),
          text: files_for_export(%w[plainText djvuXML], false) }
      end

      def object_filesets_for_export(object_files, include_files = true)
        object_filesets = []
        %w[metadata image text].each do |fileset_type|
          next if object_files[fileset_type.to_sym][:files].blank?
          object_fileset = {
            created_at: create_date,
            updated_at: modified_date,
            file_set_of: { ark_id: pid },
            file_set_type: fileset_type,
            metastreams: {
              administrative: { access_edit_group: rightsMetadata.access(2).machine.group },
              workflow: {
                ingest_filepath: workflowMetadata.source.ingest_filepath[0],
                ingest_filename: workflowMetadata.source.ingest_filename[0],
                ingest_datastream: workflowMetadata.source.ingest_datastream[0],
                processing_state: workflowMetadata.item_status.state[0] == 'published' ? 'complete' : 'derivatives'
              }.compact
            }
          }
          object_fileset[:files] = object_files[fileset_type.to_sym][:files] if include_files
          # remove :filestream_of property from object_files hashes, since it references
          # DigitalObject rather than as-yet-uncreated FileSet
          object_fileset[:files].each do |file_hash|
            file_hash[:file].delete(:filestream_of)
          end
          object_filesets << { fileset: object_fileset }
        end
        object_filesets
      end

      # if this is a wrapper object for Book/Volume, skip it
      # volume stuff from DC2 is deprecated (and there are only 2 of these anyway)
      def is_volume_wrapper?
        volumes = Bplmodels::Finder.getVolumeObjects(pid)
        volumes.present? ? true : false
      end
    end
  end
end