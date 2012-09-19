module Bplmodels
  module Datastreams
    class AdminDatastream < ActiveFedora::NokogiriDatastream
      include OM::XML::Document

      ADMIN_NS = 'http://www.bpl.org/repository/xml/ns/admin'
      ADMIN_SCHEMA = 'http://www.bpl.org/repository/xml/xsd/admin.xsd'
      ADMIN_PARAMS = {
          "version"            => "0.0.1",
          "xmlns:xlink"        => "http://www.w3.org/1999/xlink",
          "xmlns:xsi"          => "http://www.w3.org/2001/XMLSchema-instance",
          "xmlns"              => ADMIN_NS,
          "xsi:schemaLocation" => "#{ADMIN_NS} #{ADMIN_SCHEMA}",
      }

      set_terminology do |t|
        t.root :path => 'admin', :xmlns => ADMIN_NS

        t.item_status {
          t.state(:path=>"state")
          t.state_comment(:path=>"state_comment")
        }
      end

      def self.xml_template
        Nokogiri::XML::Builder.new do |xml|
          xml.mods(ADMIN_PARAMS) {

            xml.item_status {
              xml.state
              xml.state_comment
            }
          }
        end.doc
      end
    end
  end
end