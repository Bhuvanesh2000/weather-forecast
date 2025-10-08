# spec/services/weather_service_spec.rb

require "rails_helper"
require "webmock/rspec"

RSpec.describe WeatherService, type: :service do
  let(:lat) { 17.4399 }
  let(:lon) { 78.3489 }
  let(:api_key) { "dummy_key" }
  let(:base_url) { "http://api.weatherapi.com/v1/forecast.json" }

  before do
    stub_const("ENV", ENV.to_h.merge("WEATHER_API_KEY" => api_key))
  end

  describe ".fetch" do
    context "when valid response from API" do
      let(:response_body) do
        {
          "current" => { "temp_c" => 28.5, "condition" => { "text" => "Sunny" } },
          "forecast" => {
            "forecastday" => [
              { "day" => { "maxtemp_c" => 30, "mintemp_c" => 20 } }
            ]
          }
        }.to_json
      end

      before do
        stub_request(:get, base_url)
          .with(query: hash_including(q: "#{lat},#{lon}", key: api_key))
          .to_return(status: 200, body: response_body)
      end

      it "returns current temp, condition, high, and low" do
        result = described_class.fetch(lat, lon)
        expect(result).to eq({
          current_temp: 28.5,
          condition: "Sunny",
          high: 30,
          low: 20
        })
      end
    end

    context "when API key is missing" do
      before { stub_const("ENV", ENV.to_h.merge("WEATHER_API_KEY" => nil)) }

      it "raises WeatherServiceError" do
        expect { described_class.fetch(lat, lon) }.to raise_error(WeatherService::WeatherServiceError)
      end
    end

    context "when latitude or longitude is missing" do
      it "raises ArgumentError for nil lat" do
        expect { described_class.fetch(nil, lon) }.to raise_error(ArgumentError)
      end

      it "raises ArgumentError for nil lon" do
        expect { described_class.fetch(lat, nil) }.to raise_error(ArgumentError)
      end
    end

    context "when API returns error" do
      before do
        stub_request(:get, base_url)
          .with(query: hash_including(q: "#{lat},#{lon}", key: api_key))
          .to_return(status: 500)
      end

      it "returns nil" do
        expect(described_class.fetch(lat, lon)).to be_nil
      end
    end

    context "when API returns invalid JSON" do
      before do
        stub_request(:get, base_url)
          .with(query: hash_including(q: "#{lat},#{lon}", key: api_key))
          .to_return(status: 200, body: "invalid json")
      end

      it "returns nil" do
        expect(described_class.fetch(lat, lon)).to be_nil
      end
    end
  end
end
