module Bplmodels
  class Institution < Bplmodels::RelationBase
    include Bplmodels::DatastreamExport

    has_many :collections, :class_name=> "Bplmodels::Collection", :property=> :is_member_of

    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

    has_many :exemplary_image, :class_name => "Bplmodels::File", :property=> :is_exemplary_image_of

    #A collection can have another collection as a member, or an image
    def insert_member(fedora_object)
      if (fedora_object.instance_of?(Bplmodels::Collection))

        #add to the members ds
        members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>fedora_object.fedora_name)

        #add to the rels-ext ds
        fedora_object.institutions << selfinstitutioninstitution
        self.collections << fedora_object

      end

      fedora_object.save!
      self.save!

    end

    def fedora_name
      'institution'
    end

    def new_examplary_image(file_path, file_name)

      #Delete any old images
      ActiveFedora::Base.find_in_batches('is_exemplary_image_of_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |image_solr|
            current_image_file = ActiveFedora::Base.find(image_solr['id']).adapt_to_cmodel
            current_image_file.delete
        }
      end


      image_file = Bplmodels::ImageFile.mint(:parent_pid=>self.pid, :local_id=>file_name, :local_id_type=>'File Name', :label=>file_name, :institution_pid=>self.pid)

      datastream = 'productionMaster'
      image_file.send(datastream).content = ::File.open(file_path)

      if file_name.split('.').last.downcase == 'tif'
        image_file.send(datastream).mimeType = 'image/tiff'
      elsif file_name.split('.').last.downcase == 'jpg'
        image_file.send(datastream).mimeType = 'image/jpeg'
      elsif file_name.split('.').last.downcase == 'jp2'
        image_file.send(datastream).mimeType = 'image/jp2'
      elsif file_name.split('.').last.downcase == 'png'
        image_file.send(datastream).mimeType = 'image/png'
      elsif file_name.split('.').last.downcase == 'txt'
        image_file.send(datastream).mimeType = 'text/plain'
      else
        #image_file.send(datastream).mimeType = 'image/jpeg'
        raise "Could not find a mimeType for #{file_name.split('.').last.downcase}"
      end

      image_file.send(datastream).dsLabel = file_name.gsub(/\.(tif|TIF|jpg|JPG|jpeg|JPEG|jp2|JP2|png|PNG|txt|TXT)$/, '')

      #FIXME!!!
      original_file_location = "Uploaded file of #{file_path}"
      image_file.workflowMetadata.insert_file_source(original_file_location,file_name,datastream)
      image_file.workflowMetadata.item_status.state = "published"
      image_file.workflowMetadata.item_status.state_comment = "Added via the institution admin form using Bplmodels new_exemplary_image method on " + Time.new.year.to_s + "/" + Time.new.month.to_s + "/" + Time.new.day.to_s

      image_file.add_relationship(:is_image_of, "info:fedora/" + self.pid)
      image_file.add_relationship(:is_file_of, "info:fedora/" + self.pid)
      image_file.add_relationship(:is_exemplary_image_of, "info:fedora/" + self.pid)


      image_file.save
      image_file
    end

    def to_solr(doc = {} )
      doc = super(doc)



      # description
      doc['abstract_tsim'] = self.descMetadata.abstract

      # url
      doc['institution_url_ss'] = self.descMetadata.local_other

      # sublocations
      doc['sub_location_ssim']  = self.descMetadata.item_location.holding_simple.copy_information.sub_location

      # hierarchical geo
      country = self.descMetadata.subject.hierarchical_geographic.country
      state = self.descMetadata.subject.hierarchical_geographic.state
      county = self.descMetadata.subject.hierarchical_geographic.county
      city = self.descMetadata.subject.hierarchical_geographic.city
      city_section = self.descMetadata.subject.hierarchical_geographic.city_section

      doc['subject_geo_country_ssim'] = country
      doc['subject_geo_state_ssim'] = state
      doc['subject_geo_county_ssim'] = county
      doc['subject_geo_city_ssim'] = city
      doc['subject_geo_citysection_ssim'] = city_section

      # add " (county)" to county values for better faceting
      county_facet = []
      if county.length > 0
        county.each do |county_value|
          county_facet << county_value + ' (county)'
        end
      end

      # add hierarchical geo to subject-geo text field
      doc['subject_geographic_tsim'] = country + state + county + city + city_section

      # add hierarchical geo to subject-geo facet field
      doc['subject_geographic_ssim'] = country + state + county_facet + city + city_section

      # coordinates
      coords = self.descMetadata.subject.cartographics.coordinates
      doc['subject_coordinates_geospatial'] = coords
      doc['subject_point_geospatial'] = coords

      # TODO: DRY this out with Bplmodels::ObjectBase
      # geographic data as GeoJSON
      # subject_geojson_facet_ssim = for map-based faceting + display
      # subject_hiergeo_geojson_ssm = for display of hiergeo metadata
      doc['subject_geojson_facet_ssim'] = []
      doc['subject_hiergeo_geojson_ssm'] = []
      0.upto self.descMetadata.subject.length-1 do |subject_index|

        this_subject = self.descMetadata.mods(0).subject(subject_index)

        # TGN-id-derived geo subjects. assumes only longlat points, no bboxes
        if this_subject.cartographics.coordinates.any? && this_subject.hierarchical_geographic.any?
          geojson_hash_base = {type: 'Feature', geometry: {type: 'Point'}}
          # get the coordinates
          coords = coords[0]
          if coords.match(/^[-]?[\d]*[\.]?[\d]*,[-]?[\d]*[\.]?[\d]*$/)
            geojson_hash_base[:geometry][:coordinates] = coords.split(',').reverse.map { |v| v.to_f }
          end

          facet_geojson_hash = geojson_hash_base.dup
          hiergeo_geojson_hash = geojson_hash_base.dup

          # get the hierGeo elements, except 'continent'
          hiergeo_hash = {}
          ModsDescMetadata.terminology.retrieve_node(:subject,:hierarchical_geographic).children.each do |hgterm|
            hiergeo_hash[hgterm[0]] = '' unless hgterm[0].to_s == 'continent'
          end
          hiergeo_hash.each_key do |k|
            hiergeo_hash[k] = this_subject.hierarchical_geographic.send(k)[0].presence
          end
          hiergeo_hash.reject! {|k,v| !v } # remove any nil values

          hiergeo_hash[:other] = this_subject.geographic[0] if this_subject.geographic[0]

          hiergeo_geojson_hash[:properties] = hiergeo_hash
          facet_geojson_hash[:properties] = {placename: DatastreamInputFuncs.render_display_placename(hiergeo_hash)}

          if geojson_hash_base[:geometry][:coordinates].is_a?(Array)
            doc['subject_hiergeo_geojson_ssm'].append(hiergeo_geojson_hash.to_json)
            doc['subject_geojson_facet_ssim'].append(facet_geojson_hash.to_json)
          end
        end
      end

      doc['institution_pid_si'] = self.pid
      doc['institution_pid_ssi'] = self.pid

      # basic genre
      basic_genre = 'Institutions'
      doc['genre_basic_ssim'] = basic_genre
      doc['genre_basic_tsim'] = basic_genre

      # physical location
      # slightly redundant, but needed for faceting and A-Z filtering
      institution_name = self.descMetadata.mods(0).title.first
      doc['physical_location_ssim'] = institution_name
      doc['physical_location_tsim'] = institution_name

      exemplary_check = Bplmodels::ImageFile.find_with_conditions({"is_exemplary_image_of_ssim"=>"info:fedora/#{self.pid}"}, rows: '1', fl: 'id' )
      if exemplary_check.present?
        doc['exemplary_image_ssi'] = exemplary_check.first["id"]
      end

      doc['ingest_origin_ssim'] = self.workflowMetadata.item_source.ingest_origin if self.workflowMetadata.item_source.ingest_origin.present?
      doc['ingest_path_ssim'] = self.workflowMetadata.item_source.ingest_filepath if self.workflowMetadata.item_source.ingest_filepath.present?


      doc

    end

    def export_all_to_curator(include_files = true)
      export_logfile = Logger.new("log/#{pid.gsub(/\:/, '_')}_curator-export-failures.log")
      export_logfile.level = Logger::DEBUG
      export_logfile.debug "\n------\n------\nError log for #{label} (#{pid})"

      export_results = Hash.new { |h, k| h[k] = [] }
      total_bytes = 0
      filesets_count = 0
      blobs_count = 0
      puts "Starting export for #{label} (#{pid})"
      puts "Gathering institution info ..."

      all_cols = collections
      cols_count = all_cols.count
      puts "#{cols_count} Collections found"

      cols_objects = {}
      all_cols.each do |col|
        cols_objects[col.pid] = { success: false, pids: [] }
        Bplmodels::ObjectBase.find_in_batches("administrative_set_ssim" => "info:fedora/#{col.pid}") do |batch|
          batch.each { |doc| cols_objects[col.pid][:pids] << doc['id'] }
        end
      end
      objs_count = 0
      cols_objects.each_value do |col_hash|
        objs_count += col_hash[:pids].count
      end
      puts "#{objs_count} DigitalObjects found"

      puts "---------------------------------------"
      puts "---------------------------------------"
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = export_to_curator(include_files)
      if result[:success] == true
        puts "---------------------------------------"
        puts "---------------------------------------"
        puts "Starting collection export; #{cols_count} total collections"
        all_cols.each_with_index do |col, index|
          puts "exporting collection #{index + 1} of #{cols_count}"
          col_result = col.export_to_curator(include_files)
          if col_result[:success] == true
            cols_objects[col.pid][:success] = true
            export_results[:cols_exported] << col.pid
          end
        end

        puts "---------------------------------------"
        puts "---------------------------------------"
        puts "Finished exporting collections"

        cols_objects.each do |col_key, col_hash|
          if col_hash[:success] == true
            puts "---------------------------------------"
            puts "---------------------------------------"
            puts "Starting object export for collection: #{col_key}"
            col_objs_count = col_hash[:pids].count
            col_hash[:pids].each_with_index do |obj_pid, o_index|
              puts "exporting object #{o_index + 1} of #{col_objs_count}"
              begin
                obj = Bplmodels::ObjectBase.find(obj_pid).adapt_to_cmodel
                obj_result = obj.export_to_curator(include_files)
                if obj_result[:success] == true
                  export_results[:objs_exported] << obj_pid
                  total_bytes += obj_result[:total_bytes] if obj_result[:total_bytes]
                  filesets_count += obj_result[:total_filesets] if obj_result[:total_filesets]
                  blobs_count += obj_result[:total_blobs] if obj_result[:total_blobs]
                end
              rescue => e
                export_results[:objs_failed] << [obj_pid, e]
                export_logfile.debug "PID: #{obj_pid}, ERROR: #{e}"
                puts "OBJECT EXPORT FAILED! PID: #{obj_pid}, ERROR: #{e}"
              end
            end
          end
        end

        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        elapsed = end_time - start_time
        elapsed_str = Time.at(elapsed).utc.strftime("%H:%M:%S")
        total_bytes_str = ApplicationController.helpers.number_to_human_size(total_bytes)
        bytes_per_min_str = ApplicationController.helpers.number_to_human_size(total_bytes / (elapsed / 60))

        # output results
        puts "---------------------------------------"
        puts "---------------------------------------\n"
        puts "Export finished for #{label} (#{pid})!\n"
        puts "#{export_results[:cols_exported].count} of #{cols_count} Collections exported"
        puts "#{export_results[:objs_exported].count} of #{objs_count} DigitalObjects exported"
        puts "#{filesets_count} FileSets exported"
        puts "#{blobs_count} Blobs exported"
        puts "#{export_results[:objs_failed].count} failures\n\n"
        puts "Total time: #{elapsed_str}"
        puts "Total bytes exported: #{total_bytes_str}"
        puts "Bytes per minute: #{bytes_per_min_str}\n\n"
        report_alert = "Writing reports as CSV to #{BPL_CONFIG_GLOBAL['export_reports_location']}/#{name_abbreviation}_#{pid.gsub(/\:/, '_')}_export-report_*.csv"
        puts report_alert
        export_logfile.debug report_alert
        CSV.open("#{BPL_CONFIG_GLOBAL['export_reports_location']}/#{name_abbreviation}_#{pid.gsub(/\:/, '_')}_export-report_summary.csv", 'w') do |csv_obj|
          csv_obj << ['EXPORT SUMMARY FOR:', "#{label} (#{pid})"]
          csv_obj << ['', '']
          csv_obj << ["Collections found:", cols_count]
          csv_obj << ["Collections exported:", export_results[:cols_exported].count]
          csv_obj << ["DigitalObjects found:", objs_count]
          csv_obj << ["DigitalObjects exported:", export_results[:objs_exported].count]
          csv_obj << ["FileSets exported:", filesets_count]
          csv_obj << ["Blobs exported:", blobs_count]
          csv_obj << ["Failures:", export_results[:objs_failed].count]
          csv_obj << ['', '']
          csv_obj << ['Total time:', elapsed_str]
          csv_obj << ['Total bytes:', total_bytes_str]
          csv_obj << ['Bytes per minute:', bytes_per_min_str]
        end
        export_results.each do |arr_name, arr|
          CSV.open("#{BPL_CONFIG_GLOBAL['export_reports_location']}/#{name_abbreviation}_#{pid.gsub(/\:/, '_')}_export-report_#{arr_name}.csv", 'w') do |csv_obj|
            arr.each do |arr_pid|
              csv_obj << if arr_name == :objs_failed
                           [arr_pid[0], arr_pid[1]]
                         else
                           [arr_pid]
                         end
            end
          end
        end
        true
      else
        puts "FAILED TO EXPORT #{label} (#{pid}), canceling!"
        false
      end
    end

    def export_data_for_curator_api(include_files = false)
      export_hash = {
        ark_id: pid,
        created_at: create_date,
        updated_at: modified_date,
        name: (descMetadata.mods(0).title_info(0).nonSort[0].presence || '') + descMetadata.title.first,
        # double quotes in #delete arg below are correct, DO NOT CHANGE
        abstract: (abstract.delete("\n").delete("\r").gsub(/<br[ \/]*>/, '<br/>') if abstract.present?),
        url: descMetadata.identifier.first,
        location: location_for_export_hash,
        metastreams: {
          administrative: {
            destination_site: workflowMetadata.destination.site,
            access_edit_group: rightsMetadata.access(2).machine.group
          },
          workflow: {
            publishing_state: workflowMetadata.item_status.state[0]
          }
        }
      }
      thumbnail_files = Bplmodels::Finder.getImageFiles(pid)
      if thumbnail_files.present?
        thumbnail = Bplmodels::ImageFile.find(thumbnail_files.first['id'])
        thumb_export = thumbnail.filestreams_for_export(['thumbnail300'], 'institution', false)
        export_hash[:files] = thumb_export if include_files
      end
      { institution: export_hash.compact }
    end

    def location_for_export_hash
      return nil unless descMetadata.subject(0).hierarchical_geographic(0).city.present?
      {
        label: descMetadata.subject(0).hierarchical_geographic(0).city.first,
        authority_code: "tgn",
        id_from_auth: descMetadata.subject(0).valueURI.first&.match(/[0-9]*\z/).to_s,
        coordinates: descMetadata.subject(0).cartographics.coordinates.first
      }
    end

    # create export manifest CSV, to be verified after migration
    # CSV contains object class and ark id for all collections, objects, filesets, attachments
    def curator_export_manifest(path_to_csv = nil)
      puts "Creating export manifest, this may take a minute..."
      path_to_csv ||= BPL_CONFIG_GLOBAL['export_reports_location']
      data_for_csv = []
      data_for_csv << %w(curator_model ark_id attachment_type parent_ark_id file_name_base)
      data_for_csv << ['Institution', pid, '', '', '']

      col_pids = collections.map(&:pid)
      col_pids.each do |col_pid|
        data_for_csv << ['Collection', col_pid, '', '', '']
      end

      col_obj_pids = []
      col_pids.each do |col_pid|
        Bplmodels::ObjectBase.find_in_batches("administrative_set_ssim" => "info:fedora/#{col_pid}") do |batch|
          batch.each { |doc| col_obj_pids << doc['id'] }
        end
      end

      col_obj_pids.each do |obj_pid|
        obj = Bplmodels::ObjectBase.find(obj_pid).adapt_to_cmodel
        data_for_csv << ['DigitalObject', obj.pid, '', '', '']
        filesets = obj.filesets_for_export
        filesets.each do |fileset|
          fs_hash = fileset.fetch(:file_set)
          fs_ark_id = fs_hash.fetch(:ark_id, '')

          fs_parent_ark_id = fs_hash.fetch(:file_set_of).fetch(:ark_id)
          fs_fn_base = fs_hash.fetch(:file_name_base)
          data_for_csv << ["Filestreams::#{fs_hash.fetch(:file_set_type).capitalize}", fs_ark_id, '',
                           fs_parent_ark_id, fs_fn_base]
          fs_hash.fetch(:files).each do |f_hash|
            data_for_csv << ["ActiveStorage::Attachment", fs_ark_id, f_hash.fetch(:file_type),
                             fs_parent_ark_id, fs_fn_base]
          end
        end
      end

      csv_fullpath = "#{path_to_csv}/#{name_abbreviation}_#{pid.gsub(/\:/, '_')}_export-manifest_#{Time.zone.now.strftime('%Y-%m-%d')}.csv"
      CSV.open(csv_fullpath, 'w') do |csv_obj|
        data_for_csv.each { |v| csv_obj << v }
      end
      puts "Export manifest created: #{csv_fullpath}"
    end

    def name_abbreviation
      label.split(' ').map { |v| v.first.downcase }.join.gsub(/\W/, '')
    end

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    def self.mint(args)
      args[:namespace_id] ||= ARK_CONFIG_GLOBAL['namespace_commonwealth_pid']

      #TODO: Duplication check here to prevent over-writes?

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>ARK_CONFIG_GLOBAL['namespace_commonwealth_pid'], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})
      begin
        as_json = JSON.parse(response.body)
      rescue => ex
        raise('Error in JSON response for minting an institution pid.')
      end

      Bplmodels::Institution.find_in_batches('id'=>as_json["pid"]) do |group|
        group.each { |solr_result|
          return as_json["pid"]
        }
      end

      object = self.new(:pid=>as_json["pid"])

      title = Bplmodels::DatastreamInputFuncs.getProperTitle(args[:label])
      object.label = args[:label]
      object.descMetadata.insert_title(title[0], title[1])

      object.read_groups = ["public"]
      object.edit_groups = ["superuser", 'admin[' + object.pid + ']']

      return object
    end

  end
end
