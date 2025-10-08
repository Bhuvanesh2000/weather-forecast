# app/services/geocoding_service.rb
#
# Service object responsible for converting a human-readable address
# into geographic coordinates (latitude, longitude) and postal code
# using the Google Maps Geocoding API.
#
# Responsibilities:
# - Handle external API requests safely
# - Parse JSON response to extract relevant geolocation data
# - Return a consistent hash with lat, lon, and postal_code
# - Return nil if address cannot be resolved
#
# Note: This service uses RestClient for HTTP requests. API key is
# expected to be set in ENV['GOOGLE_MAPS_API_KEY'].

class GeocodingService
  BASE_URL = "https://maps.googleapis.com/maps/api/geocode/json".freeze

  class GeocodingError < StandardError; end

  # Looks up latitude, longitude, and postal code for a given address
  #
  # @param address [String] The human-readable address
  # @return [Hash, nil] Returns a hash with keys :lat, :lon, :postal_code
  #                     or nil if address cannot be resolved
  def self.lookup(address)
    raise ArgumentError, "Address cannot be blank" if address.to_s.strip.empty?
    raise GeocodingError, "Google Maps API key missing" if ENV["GOOGLE_MAPS_API_KEY"].blank?

    params = { address: address, key: ENV["GOOGLE_MAPS_API_KEY"] }

    response = RestClient.get(BASE_URL, { params: params })
    return nil unless response.code == 200

    data = JSON.parse(response.body)
    result = data["results"].first
    return nil unless result

    # Extract latitude and longitude
    lat = result.dig("geometry", "location", "lat")
    lon = result.dig("geometry", "location", "lng")

    # Extract postal code from address components
    postal_code = extract_postal_code(result["address_components"])

    { lat: lat, lon: lon, postal_code: postal_code }
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("GeocodingService: API request failed: #{e.response}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("GeocodingService: JSON parsing failed: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("GeocodingService: Unexpected error: #{e.message}")
    nil
  end

  private_class_method

  # Extracts the postal code from Google Maps address components
  #
  # @param components [Array<Hash>] Address components from API response
  # @return [String, nil] Postal code if present, nil otherwise
  def self.extract_postal_code(components)
    components.each do |component|
      return component["long_name"] if component["types"].include?("postal_code")
    end
    nil
  end
end
