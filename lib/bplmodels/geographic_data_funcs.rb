module Bplmodels
  class GeographicDataFuncs
    class << self
      ##
      # create a hash of mods:hierarchicalGeographic data
      # like {country: "United States", state: "Virginia", city: "Richmond"}
      # @param subject [Array]
      # @return [Hash]
      def hiergeo_hash(subject)
        hiergeo_hash = {}
        ModsDescMetadata.terminology.retrieve_node(:subject, :hierarchical_geographic).children.each do |hgterm|
          hiergeo_hash[hgterm[0]] = '' unless hgterm[0].to_s == 'continent'
        end
        hiergeo_hash.each_key do |k|
          hiergeo_hash[k] = subject.hierarchical_geographic.send(k)[0].presence
        end
        hiergeo_hash.select! { |_k, v| v }
      end

      ##
      # take a simple bounding box from MODS and return in various WKT type syntax
      # @param bbox [String] the basic bbox string: minX minY maxX maxY
      # @param output_format [String] the format to be output
      # @return [String || Array] depends on output_format param
      def bbox_formatter(bbox, output_format)
        coords_array = bbox.split(' ').map(&:to_f)
        min_x = coords_array[0]
        min_y = coords_array[1]
        max_x = coords_array[2]
        max_y = coords_array[3]
        case output_format
        when 'wkt_array' # used for geojson bounding box
          if min_x > max_x
            min_x, max_x = bbox_dateline_fix(min_x, max_x)
          end
          coords_to_wkt_polygon(min_x, min_y, max_x, max_y)
        when 'wkt_envelope' # used for subject_bbox_geospatial field
          coords = normalize_bbox(min_x, min_y, max_x, max_y)
          "ENVELOPE(#{coords[0]}, #{coords[2]}, #{coords[3]}, #{coords[1]})"
        when 'wkt_polygon' # may need if we use Solr JTS for _geospatial field
          wkt_polygon = coords_to_wkt_polygon(min_x, min_y, max_x, max_y)
          wkt_order_strings = wkt_polygon.map { |coords| "#{coords[0]} #{coords[1]}" }
          "POLYGON((#{wkt_order_strings.join(', ')}))"
        else
          Rails.logger.error("UNSUPPORTED BBOX OUTPUT REQUESTED: '#{output_format}'")
        end
      end

      private

      ##
      # return array of coordinate arrays corresponding to a WKT polygon
      # @param min_x [Float] minimum longitude
      # @param min_y [Float] minimum latitude
      # @param max_x [Float] maximum longitude
      # @param max_y [Float] maximum latitude
      # @return [Array]
      def coords_to_wkt_polygon(min_x, min_y, max_x, max_y)
        [[min_x, min_y],
         [max_x, min_y],
         [max_x, max_y],
         [min_x, max_y],
         [min_x, min_y]]
      end

      ##
      # checks and fixes any 'out of bounds' latitude values
      # sometimes passed from NBLMC georeferencing process
      # or Solr throws error: not in boundary Rect(minX=-180.0,maxX=180.0,minY=-90.0,maxY=90.0)
      # @param min_x [Float] minimum longitude
      # @param min_y [Float] minimum latitude
      # @param max_x [Float] maximum longitude
      # @param max_y [Float] maximum latitude
      # @return [Array]
      def normalize_bbox(min_x, min_y, max_x, max_y)
        min_x = (min_x + 360) if min_x < -180
        min_y = -90.0 if min_y < -90
        max_x = (max_x - 360) if max_x > 180
        max_y = 90.0 if max_y > 90
        [min_x, min_y, max_x, max_y]
      end

      ##
      # if this bbox crosses the dateline (min_x > max_x), have to adjust latitude values
      # so that bbox overlay displays properly in blacklight-maps views (Leaflet)
      # @param min_x [Float] minimum longitude
      # @param max_x [Float] maximum longitude
      # @return [Array]
      def bbox_dateline_fix(min_x, max_x)
        if min_x > 0
          degrees_to_add = 180 - min_x
          min_x = -(180 + degrees_to_add)
        elsif min_x < 0 && max_x < 0
          degrees_to_add = 180 + max_x
          max_x = 180 + degrees_to_add
        else
          Rails.logger.error("This bbox format was not parsed correctly: '#{coords}'")
        end
        [min_x, max_x]
      end
    end
  end
end
