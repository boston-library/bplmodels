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
      adapted_object = self.adapt_to(klass)

      self.relationships.each_statement do |statement|
        if statement.predicate == "info:fedora/fedora-system:def/model#hasModel"
          self.remove_relationship(:has_model, statement.object)
        end
      end

      adapted_object.assert_content_model
      adapted_object.save
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

    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    def self.mint(args)

      #TODO: Duplication check here to prevent over-writes?

      args[:namespace_id] ||= ARK_CONFIG_GLOBAL['namespace_commonwealth_pid']

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:parent_pid=>args[:parent_pid], :namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>args[:namespace_id], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})
      as_json = JSON.parse(response.body)

      dup_check = ActiveFedora::Base.find(:pid=>as_json["pid"])
      if dup_check.present?
        return as_json["pid"]
      end

      puts 'pid is: ' + as_json["pid"]
      object = self.new(:pid=>as_json["pid"])

      return object
    end

  end
end