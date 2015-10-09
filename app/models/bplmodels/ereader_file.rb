module Bplmodels
  class EreaderFile < Bplmodels::File

    # Use a callback method to declare which derivatives you want
    makes_derivatives :generate_derivatives

    def fedora_name
      'ereader_file'
    end



  end
end