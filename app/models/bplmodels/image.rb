module Bplmodels
  class Image < Bplmodels::SimpleObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    belongs_to :institution, :class_name => 'Bplmodels::Institution', :property => :is_member_of

    has_and_belongs_to_many :image_files, :class => "Bplmodels::ImageFile", :property=> :has_image

    def fedora_name
      'image'
    end
  end
end

