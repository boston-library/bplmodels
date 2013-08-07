module Bplmodels
  class ObjectBase < ActiveFedora::Base
    # To change this template use File | Settings | File Templates.
    include ActiveFedora::Auditable

    def save
      #self.add_relationship(:has_model, "info:fedora/afmodel:Bplmodels_ObjectBase")
      super()
    end

    def to_solr(doc = {} )
      doc = super(doc)
      puts doc['has_model_ssim']
      if doc['has_model_ssim'] != "String"
        begin
        doc['has_model_ssim'].each do |model_string|
          case model_string
            when 'info:fedora/afmodel:Bplmodels_PhotographicPrint'
              doc['active_fedora_model_ssi'] = Bplmodels::PhotographicPrint.name
            when 'info:fedora/afmodel:Bplmodels_NonPhotographicPrint'
              doc['active_fedora_model_ssi'] = Bplmodels::NonPhotographicPrint.name
            when 'info:fedora/afmodel:Bplmodels_Card'
              doc['active_fedora_model_ssi'] = Bplmodels::Card.name
            when 'info:fedora/afmodel:Bplmodels_Document'
              doc['active_fedora_model_ssi'] = Bplmodels::Document.name
            when 'info:fedora/afmodel:Bplmodels_Manuscript'
              doc['active_fedora_model_ssi'] = Bplmodels::Manuscript.name
            when 'info:fedora/afmodel:Bplmodels_Map'
              doc['active_fedora_model_ssi'] = Bplmodels::Map.name
            when 'info:fedora/afmodel:Bplmodels_Periodical'
              doc['active_fedora_model_ssi'] = Bplmodels::Periodical.name
            when 'info:fedora/afmodel:Bplmodels_Postcard'
              doc['active_fedora_model_ssi'] = Bplmodels::Postcard.name
            when 'info:fedora/afmodel:Bplmodels_Object'
              doc['active_fedora_model_ssi'] = Bplmodels::Object.name
          end
        end
        rescue
          puts "I should not be here"
        end
      end
      doc

    end

  end
end