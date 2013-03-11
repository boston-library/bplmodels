module Bplmodels
  class Institution < Bplmodels::RelationBase

    has_many :collections, :class_name=> "Bplmodels::Collection", :property=> :has_member


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

  end
end