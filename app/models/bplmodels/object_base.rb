module Bplmodels
  class ObjectBase < ActiveFedora::Base
    # To change this template use File | Settings | File Templates.
    include ActiveFedora::Auditable

    def save
      super()
    end

    #Rough initial attempt at this implementation
    #use test2.relationships(:has_model)?
    def convert_to(klass)
      #if !self.instance_of?(klass)
        self = self.adapt_to(klass)
        self.relationships.each_statement do |statement|
          if statement.predicate == "info:fedora/fedora-system:def/model#hasModel"
            self.remove_relationship(:has_model, statement.object)
          end
        end

        self.assert_content_model
        self.save
      #end

    end


    def assert_content_model
      super()
      object_superclass = self.class.superclass
      until object_superclass == ActiveFedora::Base || object_superclass == Object do
        add_relationship(:has_model, object_superclass.to_class_uri)
        object_superclass = object_superclass.superclass
      end
    end

    def to_solr(doc = {} )
      doc = super(doc)
      doc

    end

  end
end