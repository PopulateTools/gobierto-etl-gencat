# frozen_string_literal: true

module Utils
  class RowDecorator < BaseDecorator
    def initialize(row)
      @object = row
    end

    def cleaned_text(attribute)
      attr_value = @object[attribute]
      attr_value ? attr_value.squish : attr_value
    end

    def cleaned_list(attribute, separator = /\s*\+\s*/)
      attribute.split(separator).map { |item| cleaned_text(item) }
    end

    def location(attribute)
      location_name = cleaned_text(attribute)
      location = single_location_search(location_name)
      destination_object(location, location_name)
    end

    def locations_list(attribute)
      location_name = cleaned_text(attribute)
      location_search_results = Geocoder.search(location_name)
      location_search_results = [single_location_search(location_name)] unless location_search_results.count > 1
      {
        "destinations" => location_search_results.each_with_index.map do |result, idx|
          destination_object(result, location_name.split("/")[idx].strip)
        end.compact
      }
    end

    def datetime(attribute, fallback: nil)
      @object[attribute].blank? ? fallback : DateTime.parse(@object[attribute])
    end

    def economic_amount(attribute)
      @object[attribute].to_f.round(2)
    end

    def datetime_interval(attribute)
      [datetime(attribute), 1.hour.since(datetime(attribute))]
    end

    def raw_text(attribute)
      @object[attribute].to_s
    end

    private

    LOCALITY_TYPES = %w(political locality).freeze

    def geocoder_single_search(name, locality_postfix = nil)
      name = "#{ name }, #{ locality_postfix }" if locality_postfix
      results = Geocoder.search(name)
      location = results.first
    end

    def single_location_search(name)
      location = geocoder_single_search(name)

      unless location&.types&.any? { |type_name| LOCALITY_TYPES.include?(type_name) }
        LOCALITY_TYPES.each do |type|
          location = geocoder_single_search(name, type)
          break if location && location.types.any? { |type_name| LOCALITY_TYPES.include?(type_name) }
        end
      end

      location
    end

    def destination_object(location, location_name)
      return nil if location.nil?

      {
        "name" => location_name,
        "lat" => location.latitude,
        "lon" => location.longitude,
        "country_code" => Alpha2.find_by_country_name(location.country),
        "country_name" => location.country,
        "city_name" => location.city
      }
    end
  end
end
