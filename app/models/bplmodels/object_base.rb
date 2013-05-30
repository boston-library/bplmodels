module Bplmodels
  class ObjectBase < ActiveFedora::Base
    # To change this template use File | Settings | File Templates.

    def save
      self.add_relationship(:has_model, "info:fedora/afmodel:Bplmodels_ObjectBase")
      super()
    end
  end
end