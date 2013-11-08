module Bplmodels
  class ImageFile < Bplmodels::File

    has_file_datastream 'thumbnail300', :versionable=>false, :label=>'thumbnail300 datastream'

    def fedora_name
      'image_file'
    end

  end
end