# spec/views/forecasts/new.html.erb_spec.rb
require "rails_helper"

RSpec.describe "forecasts/new.html.erb", type: :view do
  before do
    render
  end

  it "displays the page title" do
    expect(rendered).to match(/Weather Forecast/)
  end

  it "renders a form for submitting an address" do
    expect(rendered).to have_selector("form.forecast-form")
  end

  it "includes a label for the address field" do
    expect(rendered).to have_selector("label.form-label", text: "Enter Address:")
  end

  it "includes a text field for address input" do
    expect(rendered).to have_selector("input.form-control[name='address']")
  end

  it "includes a submit button with the correct text" do
    expect(rendered).to have_selector("input.btn.btn-primary[type='submit'][value='Get Forecast']")
  end
end
