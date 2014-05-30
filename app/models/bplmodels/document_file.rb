module Bplmodels
  class DocumentFile < Bplmodels::File

    has_many :next_document, :class_name => "Bplmodels::DocumentFile", :property=> :is_preceding_document_of

    has_many :prev_document, :class_name => "Bplmodels::DocumentFile", :property=> :is_following_document_of
  end
end