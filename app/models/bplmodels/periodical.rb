module Bplmodels
  class Periodical < Bplmodels::SimpleObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    belongs_to :institution, :class_name => 'Bplmodels::Institution', :property => :is_member_of


    #A collection can have another collection as a member, or an image
    def insert_member(fedora_object)
      if (fedora_object.instance_of?(Bplmodels::ImageFile))

        #add to the members ds
        members.insert_member(:member_id=>fedora_object.pid, :member_title=>fedora_object.titleSet_display, :member_type=>fedora_object.fedora_name)

        #add to the rels-ext ds
        fedora_object.object << self
        self.image_files << fedora_object

      end

      fedora_object.save!
      self.save!

    end

    def fedora_name
      'periodical'
    end

    def to_solr(doc = {} )
      doc = super(doc)
      doc['active_fedora_model_ssi'] = self.class.name
      doc
    end

  end
end