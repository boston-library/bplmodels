module Bplmodels
  class CuratorExportService
    def initialize(payload: {})
      @payload = payload
    end

    def export
      request = Typhoeus::Request.new(export_url, body: @payload.to_json, method: :post,
                                      headers: { 'Content-Type' => 'application/json' })
      request.on_complete do |response|
        return true if response.code == 201

        raise StandardError,
              "The export failed with status: #{response.code}. Error: #{response.body}"
      end
      request.run
    end

    def export_url
      api_route = if @payload.keys.first == :file_set
                    "filestreams/#{@payload.fetch(:file_set).fetch(:file_set_type)}"
                  else
                    @payload.keys.first.to_s.pluralize
                  end
      "#{BPL_CONFIG_GLOBAL['curator_api']}/#{api_route}"
    end
  end
end
