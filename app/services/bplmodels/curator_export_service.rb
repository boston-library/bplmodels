module Bplmodels
  class CuratorExportService
    USER_AGENT='Bplmodels/export'.freeze

    def initialize(payload: {})
      @payload = payload
    end

    def export
      return true if object_exists?

      response = Typhoeus::Request.post(export_url, body: @payload.to_json, headers: { 'Content-Type' => 'application/json', 'User-Agent' => USER_AGENT }, cache: false, http_version: http_version)

      return true if response.code == 201

      raise StandardError, "The export failed with status: #{response.code}. Error: #{response.body}"
    end

    def export_url
      api_route = if @payload.keys.first == :file_set
                    "filestreams/#{@payload.fetch(:file_set).fetch(:file_set_type)}"
                  else
                    @payload.keys.first.to_s.pluralize
                  end
      "#{BPL_CONFIG_GLOBAL['curator_api']}/#{api_route}"
    end

    def http_version
      BPL_CONFIG_GLOBAL.fetch('curator_api_http_ver') { :httpv1_1 }.to_sym
    end

    def object_exists?
      ark = @payload.fetch(@payload.keys.first).fetch(:ark_id, nil) || ark_for_fileset
      return false if ark.blank?

      response = Typhoeus::Request.head("#{export_url}/#{ark}", headers: { 'User-Agent' => USER_AGENT }, http_version: http_version)
      response.code == 200
    end

    # needed for filesets that don't exist in Fedora (e.g. Filestreams::Metadata)
    # can't query ark-manager, try DC3 Solr instead
    def ark_for_fileset
      ark_params = {
        is_file_set_of_ssim: @payload.fetch(@payload.keys.first).fetch(:file_set_of).fetch(:ark_id),
        filename_base_ssi: @payload.fetch(@payload.keys.first).fetch(:file_name_base)
      }
      q_params = []
      ark_params.each do |k, v|
        q_params << "#{k}:\"#{v}\""
      end
      begin
        curator_solr_service = RSolr.connect(url: BPL_CONFIG_GLOBAL['curator_solr'])
        response = curator_solr_service.select(params: { q: q_params.join(' AND ') })
        docs = response['response']['docs']
        docs.count == 1 ? docs.first['id'] : nil
      rescue
        nil
      end
    end
  end
end
