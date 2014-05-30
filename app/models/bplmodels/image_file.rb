module Bplmodels
  class ImageFile < Bplmodels::File

    has_many :next_image, :class_name => "Bplmodels::ImageFile", :property=> :is_preceding_image_of

    has_many :prev_image, :class_name => "Bplmodels::ImageFile", :property=> :is_following_image_of

    # Use a callback method to declare which derivatives you want
    makes_derivatives :generate_derivatives

    def generate_derivatives
      case self.productionMaster.mimeType
        when 'application/pdf'
          #transform_datastream :productionMaster, { :thumb => "100x100>" }
        when 'audio/wav'
          #transform_datastream :productionMaster, { :mp3 => {format: 'mp3'}, :ogg => {format: 'ogg'} }, processor: :audio
        when 'video/avi'
          #transform_datastream :productionMaster, { :mp4 => {format: 'mp4'}, :webm => {format: 'webm'} }, processor: :video
        when 'image/tiff', 'image/png', 'image/jpg'
          transform_datastream :productionMaster, { :testJP2k => { recipe: :default, datastream: 'accessMaster'  } }, processor: 'jpeg2k_image'
          transform_datastream :productionMaster, { :thumb => {size: "300x300>", datastream: 'thumbnail300', format: 'jpg'} }
      end
    end

    def fedora_name
      'image_file'
    end



  end
end