require 'rails_helper'

RSpec.describe "Environment Configuration" do
  it "runs in test environment" do
    expect(Rails.env).to eq("test")
  end

  it "uses test database" do
    expect(ActiveRecord::Base.connection.current_database).to include("test")
  end

  it "has test configuration loaded" do
    expect(Rails.application.config.cache_store).to eq(:null_store)
  end
end
