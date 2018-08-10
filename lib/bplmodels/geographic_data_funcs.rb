module Bplmodels
  class GeographicDataFuncs

    ##
    # create a hash of mods:hierarchicalGeographic data
    # like {country: "United States", state: "Virginia", city: "Richmond"}
    # @param subject [Array]
    # @return [Hash]
    def self.hiergeo_hash(subject)
      hiergeo_hash = {}
      ModsDescMetadata.terminology.retrieve_node(:subject, :hierarchical_geographic).children.each do |hgterm|
        hiergeo_hash[hgterm[0]] = '' unless hgterm[0].to_s == 'continent'
      end
      hiergeo_hash.each_key do |k|
        hiergeo_hash[k] = subject.hierarchical_geographic.send(k)[0].presence
      end
      hiergeo_hash.select! { |_k, v| v }
    end

  end
end