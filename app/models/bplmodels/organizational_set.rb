module Bplmodels
  class OrganizationalSet  < Bplmodels::RelationBase

    has_many :objects, :class_name=> "Bplmodels::ObjectBase", :property=> :hasSubset


    #A collection can have another collection as a member, or an image
    def insert_member(fedora_object)
      if (fedora_object.instance_of?(Bplmodels::ObjectBase))

        #add to the members ds
        members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>fedora_object.fedora_name)

        #add to the rels-ext ds
        fedora_object.organized_sets << self
        self.objects << fedora_object

      end

      fedora_object.save!
      self.save!

    end
  end
end