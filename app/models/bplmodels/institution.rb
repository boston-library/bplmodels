module Bplmodels
  class Institution < Bplmodels::RelationBase

    has_many :collections, :class_name=> "Bplmodels::Collection", :property=> :is_member_of

    has_metadata :name => "workflowMetadata", :type => WorkflowMetadata

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

    def to_solr(doc = {} )
      doc = super(doc)

      # title fields
      main_title = self.descMetadata.title_info(0).main_title[0]
      doc['title_info_primary_tsi'] = main_title
      doc['title_info_primary_ssort'] = main_title

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
          if coords.match(/^[-]?[\d]+[\.]?[\d]*,[-]?[\d]+[\.]?[\d]*$/)
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
      as_json = JSON.parse(response.body)

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