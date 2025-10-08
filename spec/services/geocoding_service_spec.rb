require "rails_helper"
require "webmock/rspec"

RSpec.describe GeocodingService, type: :service do
  let(:address) { "Gachibowli, Hyderabad, India" }
  let(:api_key) { "dummy_key" }
  let(:base_url) { "https://maps.googleapis.com/maps/api/geocode/json" }

  before do
    stub_const("ENV", ENV.to_h.merge("GOOGLE_MAPS_API_KEY" => api_key))
  end

  describe ".lookup" do
    context "when the address is valid and API returns results" do
      let(:response_body) do
        {
          "results" => [
            {
              "geometry" => { "location" => { "lat" => 17.4399, "lng" => 78.3489 } },
              "address_components" => [
                { "long_name" => "500032", "types" => ["postal_code"] }
              ]
            }
          ],
          "status" => "OK"
        }.to_json
      end

      before do
        stub_request(:get, base_url)
          .with(query: hash_including(address: address, key: api_key))
          .to_return(status: 200, body: response_body)
      end

      it "returns lat, lon, and postal_code" do
        result = described_class.lookup(address)
        expect(result).to eq({ lat: 17.4399, lon: 78.3489, postal_code: "500032" })
      end
    end

    context "when postal code is missing in API response" do
      let(:response_body) do
        {
          "results" => [
            {
              "geometry" => { "location" => { "lat" => 17.4399, "lng" => 78.3489 } },
              "address_components" => [
                { "long_name" => "Hyderabad", "types" => ["locality"] }
              ]
            }
          ],
          "status" => "OK"
        }.to_json
      end

      before do
        stub_request(:get, base_url)
          .with(query: hash_including(address: address, key: api_key))
          .to_return(status: 200, body: response_body)
      end

      it "returns nil for postal_code" do
        result = described_class.lookup(address)
        expect(result[:postal_code]).to eq(nil)
      end
    end

    context "when address is blank" do
      it "raises ArgumentError" do
        expect { described_class.lookup("") }.to raise_error(ArgumentError, /cannot be blank/)
      end
    end

    context "when API key is missing" do
      before do
        stub_const("ENV", ENV.to_h.merge("GOOGLE_MAPS_API_KEY" => nil))
      end

      it "raises GeocodingError" do
        expect { described_class.lookup(address) }.to raise_error(GeocodingService::GeocodingError)
      end
    end

    context "when API returns error" do
      before do
        stub_request(:get, base_url)
          .with(query: hash_including(address: address, key: api_key))
          .to_return(status: 500)
      end

      it "returns nil" do
        result = described_class.lookup(address)
        expect(result).to be_nil
      end
    end

    context "when API returns invalid JSON" do
      before do
        stub_request(:get, base_url)
          .with(query: hash_including(address: address, key: api_key))
          .to_return(status: 200, body: "invalid json")
      end

      it "returns nil" do
        result = described_class.lookup(address)
        expect(result).to be_nil
      end
    end
  end
end
