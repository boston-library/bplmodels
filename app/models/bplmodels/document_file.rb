module Bplmodels
  class DocumentFile < Bplmodels::File
    has_file_datastream 'productionMaster', :versionable=>true, :label=>'productionMaster datastream'

    has_file_datastream 'thumbnail300', :versionable=>false, :label=>'thumbnail300 datastream'

    has_many :next_document, :class_name => "Bplmodels::DocumentFile", :property=> :is_preceding_document_of

    has_many :prev_document, :class_name => "Bplmodels::DocumentFile", :property=> :is_following_document_of
  end
end