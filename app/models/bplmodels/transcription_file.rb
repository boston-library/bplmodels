module Bplmodels
  class TranscriptionFile < Bplmodels::File

    # Use a callback method to declare which derivatives you want
    makes_derivatives :generate_derivatives

    def fedora_name
      'transciption_file'
    end



  end
end