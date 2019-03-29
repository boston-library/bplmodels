require 'mime/types' unless defined? MIME::Types
module Bplmodels
  class FileContentDatastream  < ActiveFedora::Datastream
    #Required for Active Fedora 9
    def prefix(path=nil)
      return ''
    end

    def extract_metadata
      Bplmodels::DatastreamInputFuncs.get_fits_xml(self)
    end

    def filename_for_characterization
      mime_type = MIME::Types[mimeType].first
      Logger.warn "Unable to find a registered mime type for #{mimeType.inspect} on #{pid}" unless mime_type
      extension = mime_type ? ".#{mime_type.extensions.first}" : ''
      ["#{pid}-#{dsVersionID}", "#{extension}"]
    end

    def to_tempfile(&block)
      if defined?(super)
        super(&block)
      else
        superless_to_tempfile(&block)
      end
    end

    protected
    def superless_to_tempfile(&block)
      return unless has_content?
      Tempfile.open(filename_for_characterization) do |f|
        f.binmode
        if content.respond_to? :read
          f.write(content.read)
        else
          f.write(content)
        end
        content.rewind if content.respond_to? :rewind
        f.rewind
        yield(f)
      end
    end
  end
end
