# frozen_string_literal: true

require "rails_helper"

RSpec.describe UrlNormalizable do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include UrlNormalizable

      # Expose the public method for testing
      def normalize(url)
        normalize_url_for_storage(url)
      end
    end
  end

  let(:normalizer) { test_class.new }

  describe "#normalize_url_for_storage" do
    context "with blank URLs" do
      it "returns nil for nil input" do
        expect(normalizer.normalize(nil)).to be_nil
      end

      it "returns nil for empty string" do
        expect(normalizer.normalize("")).to be_nil
      end

      it "returns nil for whitespace only" do
        expect(normalizer.normalize("   ")).to be_nil
      end
    end

    context "with protocol stripping" do
      it "removes https:// prefix" do
        expect(normalizer.normalize("https://example.com")).to eq("example.com")
      end

      it "removes http:// prefix" do
        expect(normalizer.normalize("http://example.com")).to eq("example.com")
      end

      it "handles URLs without protocol" do
        expect(normalizer.normalize("example.com")).to eq("example.com")
      end
    end

    context "with trailing slash removal" do
      it "removes trailing slashes" do
        expect(normalizer.normalize("example.com/")).to eq("example.com")
      end

      it "removes multiple trailing slashes" do
        expect(normalizer.normalize("example.com///")).to eq("example.com")
      end

      it "preserves path without trailing slash" do
        expect(normalizer.normalize("example.com/about")).to eq("example.com/about")
      end
    end

    context "with UTM parameter stripping" do
      it "strips utm_source" do
        expect(normalizer.normalize("example.com?utm_source=google")).to eq("example.com")
      end

      it "strips utm_medium" do
        expect(normalizer.normalize("example.com?utm_medium=email")).to eq("example.com")
      end

      it "strips utm_campaign" do
        expect(normalizer.normalize("example.com?utm_campaign=spring_sale")).to eq("example.com")
      end

      it "strips utm_term" do
        expect(normalizer.normalize("example.com?utm_term=keyword")).to eq("example.com")
      end

      it "strips utm_content" do
        expect(normalizer.normalize("example.com?utm_content=banner")).to eq("example.com")
      end

      it "strips utm_id" do
        expect(normalizer.normalize("example.com?utm_id=123")).to eq("example.com")
      end

      it "strips all UTM params together" do
        url = "example.com?utm_source=google&utm_medium=cpc&utm_campaign=test"
        expect(normalizer.normalize(url)).to eq("example.com")
      end
    end

    context "with click/tracking ID stripping" do
      it "strips fbclid (Facebook)" do
        expect(normalizer.normalize("example.com?fbclid=abc123")).to eq("example.com")
      end

      it "strips gclid (Google Ads)" do
        expect(normalizer.normalize("example.com?gclid=xyz789")).to eq("example.com")
      end

      it "strips gclsrc" do
        expect(normalizer.normalize("example.com?gclsrc=aw.ds")).to eq("example.com")
      end

      it "strips dclid" do
        expect(normalizer.normalize("example.com?dclid=abc")).to eq("example.com")
      end

      it "strips msclkid (Microsoft/Bing)" do
        expect(normalizer.normalize("example.com?msclkid=123")).to eq("example.com")
      end

      it "strips twclid (Twitter)" do
        expect(normalizer.normalize("example.com?twclid=abc")).to eq("example.com")
      end

      it "strips li_fat_id (LinkedIn)" do
        expect(normalizer.normalize("example.com?li_fat_id=123")).to eq("example.com")
      end
    end

    context "with email marketing parameter stripping" do
      it "strips mc_cid (Mailchimp)" do
        expect(normalizer.normalize("example.com?mc_cid=abc")).to eq("example.com")
      end

      it "strips mc_eid (Mailchimp)" do
        expect(normalizer.normalize("example.com?mc_eid=xyz")).to eq("example.com")
      end

      it "strips _hsenc (HubSpot)" do
        expect(normalizer.normalize("example.com?_hsenc=abc")).to eq("example.com")
      end

      it "strips _hsmi (HubSpot)" do
        expect(normalizer.normalize("example.com?_hsmi=123")).to eq("example.com")
      end
    end

    context "with other tracking parameter stripping" do
      it "strips ref" do
        expect(normalizer.normalize("example.com?ref=homepage")).to eq("example.com")
      end

      it "strips ref_src" do
        expect(normalizer.normalize("example.com?ref_src=twitter")).to eq("example.com")
      end

      it "strips _ga (Google Analytics)" do
        expect(normalizer.normalize("example.com?_ga=1.23456")).to eq("example.com")
      end

      it "strips _gl" do
        expect(normalizer.normalize("example.com?_gl=abc")).to eq("example.com")
      end

      it "strips yclid (Yandex)" do
        expect(normalizer.normalize("example.com?yclid=123")).to eq("example.com")
      end

      it "strips igshid (Instagram)" do
        expect(normalizer.normalize("example.com?igshid=abc")).to eq("example.com")
      end
    end

    context "preserving legitimate query parameters" do
      it "preserves id parameter" do
        expect(normalizer.normalize("example.com?id=123")).to eq("example.com?id=123")
      end

      it "preserves page parameter" do
        expect(normalizer.normalize("example.com?page=2")).to eq("example.com?page=2")
      end

      it "preserves product parameter" do
        expect(normalizer.normalize("example.com?product=widget")).to eq("example.com?product=widget")
      end

      it "preserves custom parameters" do
        expect(normalizer.normalize("example.com?foo=bar&baz=qux")).to eq("example.com?foo=bar&baz=qux")
      end
    end

    context "with mixed tracking and legitimate parameters" do
      it "strips tracking params while preserving legitimate ones" do
        url = "example.com?id=123&utm_source=google"
        expect(normalizer.normalize(url)).to eq("example.com?id=123")
      end

      it "handles multiple mixed params" do
        url = "example.com?page=2&fbclid=abc&category=shoes&gclid=xyz"
        result = normalizer.normalize(url)
        expect(result).to include("page=2")
        expect(result).to include("category=shoes")
        expect(result).not_to include("fbclid")
        expect(result).not_to include("gclid")
      end

      it "preserves param order for remaining params" do
        url = "example.com?a=1&utm_source=x&b=2"
        expect(normalizer.normalize(url)).to eq("example.com?a=1&b=2")
      end
    end

    context "with subpaths" do
      it "handles subpaths without query params" do
        expect(normalizer.normalize("example.com/path/to/page")).to eq("example.com/path/to/page")
      end

      it "handles subpaths with tracking params" do
        url = "example.com/about?utm_source=google"
        expect(normalizer.normalize(url)).to eq("example.com/about")
      end

      it "handles subpaths with legitimate params" do
        url = "example.com/products?category=shoes"
        expect(normalizer.normalize(url)).to eq("example.com/products?category=shoes")
      end

      it "handles deep subpaths with mixed params" do
        url = "example.com/a/b/c?id=1&fbclid=abc"
        expect(normalizer.normalize(url)).to eq("example.com/a/b/c?id=1")
      end
    end

    context "with case insensitivity" do
      it "strips uppercase UTM params" do
        expect(normalizer.normalize("example.com?UTM_SOURCE=google")).to eq("example.com")
      end

      it "strips mixed case tracking params" do
        expect(normalizer.normalize("example.com?FbClId=abc")).to eq("example.com")
      end
    end

    context "with edge cases" do
      it "handles URLs with fragments" do
        url = "example.com/page?utm_source=x#section"
        result = normalizer.normalize(url)
        expect(result).to include("#section")
        expect(result).not_to include("utm_source")
      end

      it "handles complex real-world URLs" do
        url = "https://example.com/products/widget-123?color=blue&utm_source=newsletter&utm_medium=email&size=large&fbclid=abc123"
        result = normalizer.normalize(url)
        expect(result).to eq("example.com/products/widget-123?color=blue&size=large")
      end

      it "returns original URL on parse error" do
        # Invalid characters that could cause URI parse errors are handled gracefully
        malformed_url = "example.com/page with spaces"
        # Should not raise an error
        expect { normalizer.normalize(malformed_url) }.not_to raise_error
      end
    end
  end

  describe "TRACKING_PARAMS constant" do
    it "includes all expected UTM parameters" do
      utm_params = %w[utm_source utm_medium utm_campaign utm_term utm_content utm_id]
      utm_params.each do |param|
        expect(UrlNormalizable::TRACKING_PARAMS).to include(param)
      end
    end

    it "includes common click tracking IDs" do
      click_ids = %w[fbclid gclid msclkid twclid]
      click_ids.each do |param|
        expect(UrlNormalizable::TRACKING_PARAMS).to include(param)
      end
    end

    it "is frozen to prevent modification" do
      expect(UrlNormalizable::TRACKING_PARAMS).to be_frozen
    end
  end
end
