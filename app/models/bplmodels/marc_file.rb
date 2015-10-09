module Bplmodels
  class MarcFile < Bplmodels::File

    # Use a callback method to declare which derivatives you want
    makes_derivatives :generate_derivatives

    def fedora_name
      'marc_file'
    end



  end
end