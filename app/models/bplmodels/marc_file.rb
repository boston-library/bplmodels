# NOTE: AS OF 2018-11-28, NO OBJECTS OF THIS CLASS IN REPO; OK TO DEPRECATE
module Bplmodels
  class MarcFile < Bplmodels::File

    # Use a callback method to declare which derivatives you want
    # makes_derivatives :generate_derivatives

    def fedora_name
      'marc_file'
    end



  end
end
