module Bplmodels
  class Collection < Bplmodels::RelationBase

    #has_relationship "similar_audio", :has_part, :type=>AudioRecord
    has_many :objects, :class_name=> "Bplmodels::ObjectBase", :property=> :is_member_of_collection

    belongs_to :institutions, :class_name => 'Bplmodels::Institution', :property => :is_member_of



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
      self.add_relationship(:oai_item_id, "oai:digitalcommonwealth.org:" + self.pid, true)
      self.add_relationship(:oai_set_spec, self.pid, true)
      self.add_relationship(:oai_set_name, self.label, true)
    end

    def fedora_name
      'collection'
    end

    def to_solr(doc = {} )
      doc = super(doc)

      # title fields
      main_title = self.descMetadata.title_info(0).main_title[0]
      doc['title_info_primary_tsi'] = main_title
      doc['title_info_primary_ssort'] = main_title

      # description
      doc['abstract_tsim'] = self.descMetadata.abstract

      # genre
      genre_basic = self.descMetadata.genre_basic
      doc['genre_basic_tsim'] = genre_basic
      doc['genre_basic_ssim'] = genre_basic
      genre_specific = self.descMetadata.genre_specific
      doc['genre_specific_tsim'] = genre_specific
      doc['genre_specific_ssim'] = genre_specific

      # location
      collex_location = self.descMetadata.item_location(0).physical_location
      doc['physical_location_ssim']  = collex_location
      doc['physical_location_tsim']  = collex_location
      doc['sub_location_tsim']  = self.descMetadata.item_location(0).holding_simple(0).copy_information(0).sub_location

      # name
      doc['name_personal_tsim'] = []
      doc['name_personal_role_tsim'] = []
      doc['name_corporate_tsim'] = []
      doc['name_corporate_role_tsim'] = []

      0.upto self.descMetadata.name.length-1 do |index|
        if self.descMetadata.name(index).type[0] == "personal"
          if self.descMetadata.name(index).date.length > 0
            doc['name_personal_tsim'].append(self.descMetadata.name(index).namePart[0] + ", " + self.descMetadata.name(index).date[0])
          else
            doc['name_personal_tsim'].append(self.descMetadata.name(index).namePart[0])
          end
          doc['name_personal_role_tsim'].append(self.descMetadata.name(index).role.text[0])
        elsif self.descMetadata.name(index).type[0] == "corporate"
          if self.descMetadata.name(index).date.length > 0
            doc['name_corporate_tsim'].append(self.descMetadata.name(index).namePart[0] + ", " + self.descMetadata.name(index).date[0])
          else
            doc['name_corporate_tsim'].append(self.descMetadata.name(index).namePart[0])
          end
          doc['name_corporate_role_tsim'].append(self.descMetadata.name(index).role.text[0])
        end
      end

      if self.descMetadata.name(0).type[0] == "personal"
        doc['name_personal_tsim'] =  [self.descMetadata.name(0).namePart[0]]
        doc['name_personal_role_tsim'] =  [self.descMetadata.name(0).role[0]]
      elsif self.descMetadata.name(0).type[0] == "corporate"
        doc['name_corporate_tsim'] =  [self.descMetadata.name(0).namePart[0]]
        doc['name_corporate_role_tsim'] =  [self.descMetadata.name(0).role[0]]
      end

      # access
      doc['restriction_on_access_ssm'] = self.descMetadata.restriction_on_access

      # date
      doc['date_start_dtsim'] = []
      doc['date_start_tsim'] = []
      doc['date_end_dtsim'] = []
      doc['date_end_tsim'] = []
      doc['date_facet_ssim'] = []
      date_start = -1
      date_end = -1

      if self.descMetadata.date(0).date_other[0] != nil && self.descMetadata.date(0).date_other.length > 0

      else
        if self.descMetadata.date(0).dates_created[0] != nil && self.descMetadata.date(0).dates_created[0].length == 4
          doc['date_start_dtsim'].append(self.descMetadata.date(0).dates_created[0] + '-01-01T01:00:00.000Z')
          doc['date_start_tsim'].append(self.descMetadata.date(0).dates_created[0])
          date_start = self.descMetadata.date(0).dates_created[0]
        end
        if self.descMetadata.date(0).dates_created[1] != nil && self.descMetadata.date(0).dates_created[1].length == 4
          doc['date_end_dtsim'].append(self.descMetadata.date(0).dates_created[1] + '-01-01T01:00:00.000Z')
          doc['date_end_tsim'].append(self.descMetadata.date(0).dates_created[1])
          date_end = self.descMetadata.date(0).dates_created[1]
        end

      end

      (1850..2000).step(10) do |index|
        if((date_start.to_i >= index && date_start.to_i < index+10) || (date_end.to_i != -1 && date_start.to_i >= index && date_end.to_i < index+10))
          doc['date_facet_ssim'].append(index.to_s + "s")
        end

      end

      doc['extent_tsi']  = self.descMetadata.physical_description(0).extent[0]
      doc['note_tsim'] = self.descMetadata.note


      doc

    end

  end
end
