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

    def export_for_bpl_api
      export_hash = {}
      export_hash[:ark_id] = pid
      export_hash[:created_at] = create_date
      export_hash[:updated_at] = modified_date
      export_hash[:institution] = { ark_id: institutions.pid }
      export_hash[:metastreams] = {}
      export_hash[:metastreams][:descriptive] = {
          name: descMetadata.title.first,
          abstract: abstract
      }
      export_hash[:metastreams][:administrative] = {
          destination_site: workflowMetadata.destination.site,
          harvestable: if workflowMetadata.item_status.harvestable[0] =~ /[Ff]alse/ ||
                          workflowMetadata.item_status.harvestable[0] == false
                         false
                       else
                         true
                       end,
          access_edit_group: rightsMetadata.access(2).machine.group
      }
      export_hash[:metastreams][:workflow] = {
          publishing_state: workflowMetadata.item_status.state[0]
      }
      { collection: export_hash }
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
