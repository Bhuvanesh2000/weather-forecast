require "rails_helper"

RSpec.describe ForecastsController, type: :controller do
  describe "POST #create" do
    let(:valid_address) { "Gachibowli, Hyderabad, India" }
    let(:geocode_data) { { lat: 17.44, lon: 78.34, postal_code: "500032" } }
    let(:forecast_data) { { current_temp: 28, condition: "Sunny", high: 32, low: 22 } }

    context "when address is blank" do
      it "redirects to new with flash alert" do
        post :create, params: { address: "" }
        expect(response).to redirect_to(new_forecast_path)
        expect(flash[:alert]).to eq("Address cannot be blank")
      end
    end

    context "when geocoding fails" do
      it "redirects to new with flash alert" do
        allow(GeocodingService).to receive(:lookup).and_return(nil)
        post :create, params: { address: valid_address }
        expect(response).to redirect_to(new_forecast_path)
        expect(flash[:alert]).to eq("Could not find location for '#{valid_address}'")
      end
    end

    context "when postal code is present" do
      it "fetches forecast and uses cache if available" do
        allow(GeocodingService).to receive(:lookup).and_return(geocode_data)
        allow(Rails.cache).to receive(:exist?).and_return(true)
        allow(Rails.cache).to receive(:fetch).and_return(forecast_data)

        post :create, params: { address: valid_address }
        expect(assigns(:forecast)).to eq(forecast_data)
        expect(assigns(:cached)).to be true
        expect(response).to render_template(:show)
      end
    end

    context "when postal code is nil" do
      it "fetches fresh forecast without caching" do
        allow(GeocodingService).to receive(:lookup).and_return(geocode_data.merge(postal_code: nil))
        allow(WeatherService).to receive(:fetch).and_return(forecast_data)

        post :create, params: { address: valid_address }
        expect(assigns(:forecast)).to eq(forecast_data)
        expect(assigns(:cached)).to be false
        expect(response).to render_template(:show)
      end
    end

    context "when an exception occurs" do
      it "redirects to new with a generic flash alert" do
        allow(GeocodingService).to receive(:lookup).and_raise(StandardError.new("API down"))
        post :create, params: { address: valid_address }
        expect(response).to redirect_to(new_forecast_path)
        expect(flash[:alert]).to eq("An error occurred while fetching the forecast. Please try again.")
      end
    end
  end
end
