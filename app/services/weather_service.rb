# app/services/weather_service.rb
#
# Service object responsible for fetching weather forecast data
# using WeatherAPI.com (current conditions + daily high/low).
#
# Responsibilities:
# - Fetch current temperature, condition, high and low for a given location
# - Handle API errors gracefully and log them
# - Return consistent hash format for controller consumption
# - Raise error if required input is missing or API key is not set
#
# Note: Extendable to support multiple days or extended forecast.

require "rest-client"
require "json"

class WeatherService
  BASE_URL = "http://api.weatherapi.com/v1/forecast.json".freeze

  class WeatherServiceError < StandardError; end

  # Fetches weather forecast for given latitude and longitude
  #
  # @param lat [Float] Latitude of location
  # @param lon [Float] Longitude of location
  # @param days [Integer] Optional: number of forecast days (default 1)
  # @return [Hash, nil] Hash with :current_temp, :condition, :high, :low
  def self.fetch(lat, lon, days: 1)
    raise ArgumentError, "Latitude and longitude must be provided" if lat.nil? || lon.nil?
    raise WeatherServiceError, "Weather API key is missing" if ENV["WEATHER_API_KEY"].blank?

    params = {
      key: ENV["WEATHER_API_KEY"],
      q: "#{lat},#{lon}",
      days: days
    }

    response = RestClient.get(BASE_URL, { params: params })
    return nil unless response.code == 200

    data = JSON.parse(response.body)

    # Extract forecast data for the first day
    day_forecast = data.dig("forecast", "forecastday")&.first&.dig("day")
    current = data["current"]

    return nil unless day_forecast && current

    {
      current_temp: current["temp_c"],
      condition: current.dig("condition", "text"),
      high: day_forecast["maxtemp_c"],
      low: day_forecast["mintemp_c"]
    }
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error("WeatherService: API request failed: #{e.response}")
    nil
  rescue JSON::ParserError => e
    Rails.logger.error("WeatherService: JSON parsing failed: #{e.message}")
    nil
  rescue StandardError => e
    Rails.logger.error("WeatherService: Unexpected error: #{e.message}")
    nil
  end
end
