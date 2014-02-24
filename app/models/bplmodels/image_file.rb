module Bplmodels
  class ImageFile < Bplmodels::File

    has_file_datastream 'productionMaster', :versionable=>true, :label=>'productionMaster datastream'

    has_file_datastream 'accessMaster', :versionable=>true, :label=>'accessMaster datastream'

    has_file_datastream 'thumbnail300', :versionable=>false, :label=>'thumbnail300 datastream'

    has_many :next_image, :class_name => "Bplmodels::ImageFile", :property=> :is_preceding_image_of

    has_many :prev_image, :class_name => "Bplmodels::ImageFile", :property=> :is_following_image_of

    def fedora_name
      'image_file'
    end


    #Expects the following args:
    #parent_pid => id of the parent object
    #local_id => local ID of the object
    #local_id_type => type of that local ID
    #label => label of the collection
    #institution_pid => instituional access of this file
    def self.mint(args)

      #TODO: Duplication check here to prevent over-writes?

      args[:namespace_id] ||= ARK_CONFIG_GLOBAL['namespace_commonwealth_pid']

      response = Typhoeus::Request.post(ARK_CONFIG_GLOBAL['url'] + "/arks.json", :params => {:ark=>{:parent_pid=>args[:parent_pid], :namespace_ark => ARK_CONFIG_GLOBAL['namespace_commonwealth_ark'], :namespace_id=>args[:namespace_id], :url_base => ARK_CONFIG_GLOBAL['ark_commonwealth_base'], :model_type => self.name, :local_original_identifier=>args[:local_id], :local_original_identifier_type=>args[:local_id_type]}})
      as_json = JSON.parse(response.body)

      dup_check = ActiveFedora::Base.find(:pid=>as_json["pid"])
      if dup_check.present?
        return as_json["pid"]
      end

      object = self.new(:pid=>as_json["pid"])

      object.label = args[:label]

      object.read_groups = ["public"]
      object.edit_groups = ["superuser", "admin[#{args[:parent_pid]}]"]

      return object
    end
  end
end