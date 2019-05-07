module Bplmodels
  class Institution < Bplmodels::RelationBase

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
