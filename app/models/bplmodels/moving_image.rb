module Bplmodels
  class MovingImage < Bplmodels::ComplexObjectBase

    def insert_member(fedora_object)
      if (fedora_object.instance_of?(Bplmodels::VideoFile))

        #add to the members ds
        members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>fedora_object.fedora_name)

        #add to the rels-ext ds
        fedora_object.object << self
        self.video_files << fedora_object
      end

      fedora_object.save!
      self.save!
    end

    def fedora_name
      'moving_image'
    end

    def to_solr(doc = {})
      doc = super(doc)
      doc['active_fedora_model_ssi'] = self.class.name
      doc
    end
  end
end
