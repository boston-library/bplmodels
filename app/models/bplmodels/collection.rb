module Bplmodels
  class Collection < Bplmodels::RelationBase

    #has_relationship "similar_audio", :has_part, :type=>AudioRecord
    has_many :objects, :class_name=> "Bplmodels::ObjectBase", :property=> :is_member_of_collection

    has_many :objects_casted, :class_name=> "Bplmodels::ObjectBase", :property=> :is_member_of_collection

    belongs_to :institutions, :class_name => 'Bplmodels::Institution', :property => :is_member_of

    #has_many :exemplary_image, :class_name => "ActiveFedora::Base", :property=> :is_exemplary_image_of

    # Uses the Hydra modsCollection profile for collection list
    #has_metadata :name => "members", :type => Hydra::ModsCollectionMembers

    #A collection can have another collection as a member, or an image
    def insert_member(fedora_object)
      if (fedora_object.instance_of?(Bplmodels::ObjectBase))

        #add to the members ds
        #members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>fedora_object.fedora_name

        #add to the rels-ext ds
        #fedora_object.collections << self
        #self.objects << fedora_object
        #self.add_relationship(:has_image, "info:fedora/#{fedora_object.pid}")
      elsif (fedora_object.instance_of?(Bplmodels::Institution))
        #add to the members ds
        members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>fedora_object.fedora_name)

        #add to the rels-ext ds
        fedora_object.collections << self
        self.institutions << fedora_object

      end

      fedora_object.save!
      self.save!

    end

    def add_oai_relationships
      #self.add_relationship(:oai_item_id, "oai:digitalcommonwealth.org:" + self.pid, true)
      self.add_relationship(:oai_set_spec, self.pid, true)
      self.add_relationship(:oai_set_name, self.label.gsub(' & ', ' &amp; '), true)
    end

    def insert_harvesting_status(value)
      self.workflowMetadata.insert_harvesting_status(value)
      self.add_oai_relationships if value == 'true'
    end

    def fedora_name
      'collection'
    end

    def to_solr(doc = {} )
      doc = super(doc)

      # basic genre
      basic_genre_array = ['Collections']
      Bplmodels::ObjectBase.find_in_batches('is_member_of_collection_ssim'=>"info:fedora/#{self.pid}") do |group|
        group.each { |object_id|
          #object_id_array << Bplmodels::ObjectBase.find(object_id['id']).adapt_to_cmodel
          basic_genre_array += object_id['genre_basic_ssim'] if object_id['genre_basic_ssim'].present?
        }
      end
      doc['genre_basic_ssim'] = basic_genre_array.uniq
      doc['genre_basic_tsim'] = basic_genre_array.uniq

      # description
      doc['abstract_tsim'] = self.descMetadata.abstract

      # institution
      if self.institutions
        collex_location = self.institutions.label.to_s
        doc['physical_location_ssim'] = collex_location
        doc['physical_location_tsim'] = collex_location
        doc['institution_name_ssim'] = collex_location
        doc['institution_name_tsim'] = collex_location
        doc['institution_pid_ssi'] = self.institutions.pid
      end

      # thumbnail
      exemplary_check = Bplmodels::File.find_with_conditions({'is_exemplary_image_of_ssim' => "info:fedora/#{self.pid}"},
                                                             rows: 1,
                                                             fl: 'id, active_fedora_model_ssi')
      if exemplary_check.present?
        doc['exemplary_image_ssi'] = exemplary_check.first['id']
        if exemplary_check.first['active_fedora_model_ssi'] != 'Bplmodels::ImageFile'
          doc['exemplary_image_iiif_bsi'] = false
        end
      end

      doc

    end

    def export_data_for_curator_api(_include_files = false)
      export_hash = {
        ark_id: pid,
        created_at: create_date,
        updated_at: modified_date,
        institution: { ark_id: institutions.pid },
        name: descMetadata.title.first,
        # double quotes in #delete arg below are correct, DO NOT CHANGE
        abstract: if abstract
                    abstract.delete("\n").delete("\r").gsub(/<br[ \/]*>/, '<br/>')
                  end,
        metastreams: {
          administrative: {
            destination_site: workflowMetadata.destination.site,
            harvestable: if workflowMetadata.item_status.harvestable[0] =~ /[Ff]alse/ ||
                            workflowMetadata.item_status.harvestable[0] == false
                           false
                         else
                           true
                         end,
            hosting_status: self.class == Bplmodels::OAICollection ? 'harvested' : 'hosted',
            access_edit_group: rightsMetadata.access(2).machine.group,
            oai_header_id: self.class == Bplmodels::OAICollection ? "oai-collection-export:#{Digest::MD5.hexdigest(pid)}" : nil,
          },
          workflow: {
            publishing_state: workflowMetadata.item_status.state[0]
          }
        }
      }
      { collection: export_hash.compact }
    end

    def export_all_to_curator(include_files = true)
      export_logfile = Logger.new("log/#{pid.gsub(/\:/, '_')}_curator-export-failures.log")
      export_logfile.level = Logger::DEBUG
      export_logfile.debug "\n------\n------\nError log for #{label} (#{pid})"

      export_results = {
         objs_exported: [],
         objs_failed: [],
         objs_count: 0,
         total_bytes: 0,
         filesets_count: 0,
         blobs_count: 0
       }
      col_objects = { success: false, pids: [] }

      puts "Starting export for #{label} (#{pid})"
      puts 'Gathering collection info ...'
      Bplmodels::ObjectBase.find_in_batches("administrative_set_ssim" => "info:fedora/#{self.pid}") do |batch|
        col_objects[:pids] += batch.flat_map { |doc| doc['id'] }
      end

      export_results[:objs_count] = col_objects[:pids].count
      puts "#{export_results[:objs_count]} DigitalObjects found"
      puts "---------------------------------------"
      puts "---------------------------------------"
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = export_to_curator(include_files)
      if result[:success] == true
        puts "---------------------------------------"
        puts "---------------------------------------"
        puts "Starting object export for collection: #{self.pid}"
        col_objects[:pids].each_with_index do |obj_pid, o_index|
          puts "exporting object #{o_index + 1} of #{export_results[:objs_count]}"
          begin
            obj = Bplmodels::ObjectBase.find(obj_pid).adapt_to_cmodel
            obj_result = obj.export_to_curator(include_files)
            if obj_result[:success] == true
              export_results[:objs_exported] << obj_pid
              export_results[:total_bytes] += obj_result[:total_bytes] if obj_result[:total_bytes]
              export_results[:filesets_count] += obj_result[:total_filesets] if obj_result[:total_filesets]
              export_results[:blobs_count] += obj_result[:total_blobs] if obj_result[:total_blobs]
              next
            end
          rescue => e
            export_results[:objs_failed] << [obj_pid, e]
            export_logfile.debug "PID: #{obj_pid}, ERROR: #{e}"
            puts "OBJECT EXPORT FAILED! PID: #{obj_pid}, ERROR: #{e}"
            next
          end
        end
      end

      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      elapsed = end_time - start_time
      export_results[:elapsed_str] = Time.at(elapsed).utc.strftime("%H:%M:%S")
      export_results[:total_bytes_str] = ApplicationController.helpers.number_to_human_size(export_results[:total_bytes])
      export_results[:bytes_per_min_str] = ApplicationController.helpers.number_to_human_size(export_results[:total_bytes] / (elapsed / 60))

      puts "---------------------------------------"
      puts "---------------------------------------\n"
      puts "Export finished for #{label} (#{pid})!\n"
      puts "#{export_results[:objs_exported].count} of #{export_results[:objs_count]} DigitalObjects exported"
      puts "#{export_results[:filesets_count]} FileSets exported"
      puts "#{export_results[:blobs_count]} Blobs exported"
      puts "#{export_results[:objs_failed].count} failures\n\n"
      puts "Total time: #{export_results[:elapsed_str]}"
      puts "Total bytes exported: #{export_results[:total_bytes_str]}"
      puts "Bytes per minute: #{export_results[:bytes_per_min_str]}\n\n"

      inst_folder_name = "#{institutions.name_abbreviation}_#{institutions.pid.gsub(/\:/, '_')}"
      csv_folder = ::File.join(BPL_CONFIG_GLOBAL['export_reports_location'], inst_folder_name)

      FileUtils.mkdir_p(csv_folder)

      report_alert = "Writing reports as CSV to #{csv_folder}/#{name_abbreviation}_#{pid.gsub(/\:/, '_')}_export-report_*.csv"
      puts report_alert
      export_logfile.debug report_alert
      output_export_results_to_csv(csv_folder, export_logfile, export_results)
    end


    def output_export_results_to_csv(csv_folder, export_logfile, export_results = {})
      # output results
      begin
        CSV.open("#{csv_folder}/#{name_abbreviation}_#{pid.gsub(/\:/, '_')}_export-report_summary.csv", 'w+') do |csv_obj|
          csv_obj << ['EXPORT SUMMARY FOR:', "#{label} (#{pid})"]
          csv_obj << ['', '']
          csv_obj << ["DigitalObjects found:", export_results[:objs_count]]
          csv_obj << ["DigitalObjects exported:", export_results[:objs_exported].count]
          csv_obj << ["FileSets exported:", export_results[:filesets_count]]
          csv_obj << ["Blobs exported:", export_results[:blobs_count]]
          csv_obj << ["Failures:", export_results[:objs_failed].count]
          csv_obj << ['', '']
          csv_obj << ['Total time:', export_results[:elapsed_str]]
          csv_obj << ['Total bytes:', export_results[:total_bytes_str]]
          csv_obj << ['Bytes per minute:', export_results[:bytes_per_min_str]]
        end
      rescue => e
        puts "Failed Writing Summary CSV!"
        puts "Reason #{e.message}"
        export_logfile.error "Failed Writing Summary CSV!"
        export_logfile.error "Reason #{e.message}"
      end
      export_results.slice(:objs_exported, :objs_failed).each do |res_name, res_array|
        begin
          CSV.open("#{csv_folder}/#{name_abbreviation}_#{pid.gsub(/\:/, '_')}_export-report_#{res_name}.csv", 'w+') do |csv_obj|
            res_array.each do |res_pid|
              case res_name
              when :objs_failed
                csv_obj << [res_pid[0], res_pid[1]]
              else
                csv_obj << [res_pid]
              end
            end
          end
        rescue => e
          puts "Failed writing *_#{res_name}.csv"
          puts "Reason #{e.message}"
          export_logfile.error "Failed writing *_#{res_name}.csv"
          export_logfile.error "Reason #{e.message}"
        end
      end
    end

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    def self.mint(args)

      #TODO: Duplication check here to prevent over-writes?

      args[:namespace_id] ||= ARK_CONFIG_GLOBAL['namespace_commonwealth_pid']

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:parent_pid=>args[:parent_pid], :namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>args[:namespace_id], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})
      begin
        as_json = JSON.parse(response.body)
      rescue => ex
        raise('Error in JSON response for minting a collection pid.')
      end

      Bplmodels::Collection.find_in_batches('id'=>as_json["pid"]) do |group|
        group.each { |solr_result|
          return as_json["pid"]
        }
      end

      object = self.new(:pid=>as_json["pid"])

      title = Bplmodels::DatastreamInputFuncs.getProperTitle(args[:label])
      object.label = args[:label]
      object.descMetadata.insert_title(title[0], title[1])

      object.add_relationship(:is_member_of, "info:fedora/" + args[:parent_pid])
      uri = ARK_CONFIG_GLOBAL['url'] + '/ark:/'+ as_json["namespace_ark"] + '/' +  as_json["noid"]
      object.descMetadata.insert_access_links(nil, uri)

      object.read_groups = ["public"]
      object.edit_groups = ["superuser", "admin[#{args[:parent_pid]}]"]

      return object
    end

  end
end
