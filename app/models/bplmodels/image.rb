module Bplmodels
  class Image < Bplmodels::SimpleObjectBase
    #has_file_datastream :name => 'productionMaster', :type => ActiveFedora::Datastream

    has_and_belongs_to_many :image_files, :class => "Bplmodels::ImageFile", :property=> :has_image



  end
end

