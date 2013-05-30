module Bplmodels
  class Institution < Bplmodels::RelationBase

    has_many :collections, :class_name=> "Bplmodels::Collection", :property=> :is_member_of

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
      doc['sub_location_ssim']  = self.descMetadata.item_location.physical_location.holding_simple.copy_information.sub_location

      # hierarchical geo
      country = self.descMetadata.subject.hierarchical_geographic.country
      state = self.descMetadata.subject.hierarchical_geographic.state
      county = self.descMetadata.subject.hierarchical_geographic.county
      city = self.descMetadata.subject.hierarchical_geographic.city

      doc['subject_geo_country_tsim'] = country
      doc['subject_geo_state_tsim'] = state
      doc['subject_geo_county_tsim'] = county
      doc['subject_geo_city_tsim'] = city

      doc['subject_geographic_ssim'] = county + city


      # coordinates
      doc['subject_coordinates_ssim'] = self.descMetadata.subject.cartographics.coordinates


      doc

    end

  end
end