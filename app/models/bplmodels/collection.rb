module Bplmodels
  class Collection < Bplmodels::RelationBase

    #has_relationship "similar_audio", :has_part, :type=>AudioRecord
    has_many :objects, :class_name=> "Bplmodels::ObjectBase", :property=> :has_collection_member

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

  end
end
