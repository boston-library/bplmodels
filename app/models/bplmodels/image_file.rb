module Bplmodels
  class ImageFile < Bplmodels::File

    has_file_datastream 'productionMaster', :versionable=>true, :label=>'productionMaster datastream'

    has_file_datastream 'accessMaster', :versionable=>true, :label=>'accessMaster datastream'

    has_file_datastream 'thumbnail300', :versionable=>false, :label=>'thumbnail300 datastream'

    has_many :next_image, :class_name => "Bplmodels::ImageFile", :property=> :is_preceding_image_of

    has_many :prev_image, :class_name => "Bplmodels::ImageFile", :property=> :is_following_image_of

    def fedora_name
      'image_file'
    end



  end
end