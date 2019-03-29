module Bplmodels
  class ImageFile < Bplmodels::File

    has_many :next_image, :class_name => "Bplmodels::ImageFile", :property=> :is_preceding_image_of

    has_many :prev_image, :class_name => "Bplmodels::ImageFile", :property=> :is_following_image_of

    # Use a callback method to declare which derivatives you want
    # makes_derivatives :generate_derivatives

    def fedora_name
      'image_file'
    end

  end
end
