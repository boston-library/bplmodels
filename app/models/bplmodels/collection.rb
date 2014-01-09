module Bplmodels
  class Collection < Bplmodels::RelationBase

    #has_relationship "similar_audio", :has_part, :type=>AudioRecord
    has_many :objects, :class_name=> "Bplmodels::ObjectBase", :property=> :is_member_of_collection, :cast=>true

    has_many :objects_casted, :class_name=> "Bplmodels::ObjectBase", :property=> :is_member_of_collection, :cast=>true

    belongs_to :institutions, :class_name => 'Bplmodels::Institution', :property => :is_member_of

    has_many :image_files, :class_name => "Bplmodels::ImageFile", :property=> :is_exemplary_image_of

    has_many :image_object, :class_name => "Bplmodels::OAIObject", :property=> :is_exemplary_image_of

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
      self.add_relationship(:oai_set_name, self.label, true)
    end

    def fedora_name
      'collection'
    end

    def to_solr(doc = {} )
      doc = super(doc)

      # title fields
      title_prefix = self.descMetadata.mods(0).title_info(0).nonSort[0] ? self.descMetadata.mods(0).title_info(0).nonSort[0] + ' ' : ''
      main_title = self.descMetadata.mods(0).title_info(0).main_title[0]
      doc['title_info_primary_tsi'] = title_prefix + main_title
      doc['title_info_primary_ssort'] = main_title

      # description
      doc['abstract_tsim'] = self.descMetadata.abstract

      # institution
      if self.institutions
        collex_location = self.institutions.label.to_s
        doc['physical_location_ssim'] = collex_location
        doc['physical_location_tsim'] = collex_location
        doc['institution_pid_si'] = self.institutions.pid
        # TODO: need to remove the 3 above and refactor apps as necessary
        # collections (AKA sets) have institutions, not locations
        doc['institution_name_ssim'] = collex_location
        doc['institution_name_tsim'] = collex_location
        doc['institution_pid_ssi'] = self.institutions.pid
      end

      if self.image_files.first != nil
        doc['exemplary_image_ss'] = self.image_files.first.pid
        doc['exemplary_image_ssi'] = self.image_files.first.pid
      end

      if self.image_object.first != nil
        doc['exemplary_image_ss'] = self.image_object.first.pid
        doc['exemplary_image_ssi'] = self.image_object.first.pid
      end

      doc

    end

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    def self.mint(args)

      #TODO: Duplication check here to prevent over-writes?

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:parent_pid=>args[:parent_pid], :namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>ARK_CONFIG_GLOBAL['namespace_commonwealth_pid'], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})
      as_json = JSON.parse(response.body)
      object = self.new(:pid=>as_json["pid"])

      title = Bplmodels::DataStreamInputFuncs.getProperTitle(args[:label])
      object.label = args[:label]
      object.descMetadata.insert_title(title[0], title[1])

      object.read_groups = ["public"]
      object.edit_groups = ["superuser", 'admin[' + @institution.pid + ']']

      object.add_relationship(:is_member_of, "info:fedora/" + args[:parent_pid])
      uri = ARK_CONFIG_GLOBAL['url'] + '/ark:/'+ as_json["namespace_ark"] + '/' +  as_json["noid"]
      object.descMetadata.insert_access_links(nil, uri)

      object.add_oai_relationships

      return object
    end

  end
end
