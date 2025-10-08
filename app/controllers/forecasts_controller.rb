# app/controllers/forecasts_controller.rb
#
# Controller responsible for handling user requests related to weather forecasts.
# Provides actions to input an address, fetch current weather forecast,
# and display results, including caching logic for efficiency.
#
# Responsibilities:
# - Validate user input
# - Interact with GeocodingService to resolve addresses
# - Interact with WeatherService to fetch forecast data
# - Cache forecast results by postal code to reduce API calls
# - Render flash messages for invalid inputs
#
# Note: This controller follows single responsibility principle (SRP)
# by delegating geocoding and weather logic to service objects.

class ForecastsController < ApplicationController
  # Display the address input form
  def new
    # Nothing needed here; just renders new.html.erb
  end

  # Handle form submission to fetch forecast for a given address
  def create
    address = params[:address].to_s.strip

    # Validate input
    if address.blank?
      flash[:alert] = "Address cannot be blank"
      redirect_to new_forecast_path and return
    end

    # Resolve address to latitude, longitude, and postal code
    geocode_data = GeocodingService.lookup(address)

    unless geocode_data
      flash[:alert] = "Could not find location for '#{address}'"
      redirect_to new_forecast_path and return
    end

    postal_code = geocode_data[:postal_code]
    lat, lon = geocode_data[:lat], geocode_data[:lon]

    if postal_code.present?
      # Only cache when postal code is present
      cache_key = "weather:#{postal_code}"
      @cached = Rails.cache.exist?(cache_key)

      # Fetch forecast, caching for 30 minutes to improve performance and reduce API calls
      @forecast = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        WeatherService.fetch(lat, lon)
      end
    else
      # No postal code → always fetch fresh
      @cached = false
      @forecast = WeatherService.fetch(lat, lon)
    end

    # Render forecast results
    render :show
  rescue StandardError => e
    # Log unexpected errors for production monitoring
    Rails.logger.error("ForecastsController#create failed: #{e.message}")
    flash[:alert] = "An error occurred while fetching the forecast. Please try again."
    redirect_to new_forecast_path
  end
end
