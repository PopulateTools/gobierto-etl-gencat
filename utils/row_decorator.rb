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
      location_search_results = Geocoder.search(location_name)
      location = location_search_results.first
      destination_object(location, location_name)
    end

    def locations_list(attribute)
      location_name = cleaned_text(attribute)
      location_search_results = Geocoder.search(location_name)
      {
        "destinations" => location_search_results.map do |result|
          destination_object(result, location_name)
        end
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

    def destination_object(location, location_name)
      country = ISO3166::Country.find_country_by_name(location.country)
      {
        "name" => location_name,
        "lat" => location.latitude,
        "lon" => location.longitude,
        "country_code" => country.alpha2
      }
    end
  end
end
