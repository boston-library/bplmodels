module Bplmodels
  class FileContentDatastream  < ActiveFedora::Datastream
    include Hydra::Derivatives::ExtractMetadata

    #Required for Active Fedora 9
    def prefix(path=nil)
      return ''
    end
  end
end