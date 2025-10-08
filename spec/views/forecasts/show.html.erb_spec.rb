# spec/views/forecasts/show.html.erb_spec.rb
require "rails_helper"

RSpec.describe "forecasts/show.html.erb", type: :view do
  let(:forecast) do
    {
      current_temp: 28,
      condition: "Sunny",
      high: 32,
      low: 22
    }
  end

  context "when forecast is fresh (not cached)" do
    before do
      assign(:forecast, forecast)
      assign(:cached, false)
      render
    end

    it "displays the current temperature" do
      expect(rendered).to match(/28°C/)
    end

    it "shows the weather condition" do
      expect(rendered).to match(/Sunny/)
    end

    it "shows high and low temperatures" do
      expect(rendered).to match(/32°C \/ 22°C/)
    end

    it "indicates that the result is a fresh API call" do
      expect(rendered).to match(/Fresh API call/)
    end

    it "includes a link to search again" do
      expect(rendered).to have_link("Search Again", href: new_forecast_path)
    end
  end

  context "when forecast is retrieved from cache" do
    before do
      assign(:forecast, forecast)
      assign(:cached, true)
      render
    end

    it "indicates that the result is retrieved from cache" do
      expect(rendered).to match(/Result retrieved from cache/)
    end
  end
end
