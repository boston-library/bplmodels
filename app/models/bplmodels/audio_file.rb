module Bplmodels
  class AudioFile  < Bplmodels::File
    has_file_datastream 'productionMaster', :versionable=>true, :label=>'productionMaster datastream'



    def fedora_name
      'audio_file'
    end
  end
end