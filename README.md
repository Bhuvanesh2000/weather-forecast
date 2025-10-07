# Weather Forecast Application

A Ruby on Rails application that allows users to input an address and retrieve the current weather forecast. This project demonstrates best practices for production-ready Rails applications, including service objects, caching, unit tests, and clean UI.

---

## Features

- Input an address to fetch weather forecast
- Geocoding using Google Maps API
- Weather data retrieval using WeatherAPI.com
- Caching forecast results by postal code for 30 minutes
- Graceful handling of missing or invalid addresses
- Flash messages for errors
- Clear UI indicators for cached vs fresh results
- Fully tested with unit tests for services and controller

---

## Architecture & Design

### **Controllers**

- `ForecastsController`  
  Handles input form, validates user input, interacts with services, caches results, and renders views.  
  Follows Single Responsibility Principle (SRP) by delegating logic to service objects.

### **Services**

1. **GeocodingService**  
   - Resolves a given address to latitude, longitude, and postal code
   - Returns `nil` if geocoding fails
   - Encapsulates all API interaction logic

2. **WeatherService**  
   - Fetches forecast data from WeatherAPI.com
   - Returns current temperature, condition, high, and low
   - Does not handle caching; that’s done in the controller

### **Caching**

- Forecast results are cached using Rails cache
- Cache key is based on postal code (`weather:<postal_code>`)
- Only addresses with valid postal codes are cached
- Cached results expire after 30 minutes
- UI displays an indicator if results are from cache

### **Views**

- `new.html.erb` – Address input form  
- `show.html.erb` – Forecast results, including cache indicator  
- Styled badges for cached/fresh results

---

### **Prerequisites**

- API keys:
  - `GOOGLE_MAPS_API_KEY` – For geocoding
  - `WEATHER_API_KEY` – For weather forecast
