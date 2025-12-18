require 'rails_helper'

RSpec.describe "shared/_flash_messages", type: :view do
  describe "notice messages" do
    context "when notice is present" do
      before do
        flash[:notice] = "Success message"
        render
      end

      it "renders the notice message" do
        expect(rendered).to have_content("Success message")
      end

      it "renders flash_message partial with notice type" do
        expect(view).to render_template(partial: "shared/_flash_message")
        expect(rendered).to have_css(".alert.alert-success")
      end
    end

    context "when notice is blank" do
      before do
        flash[:notice] = ""
        render
      end

      it "does not render anything" do
        expect(rendered.strip).to be_empty
      end
    end

    context "when notice is nil" do
      before do
        flash[:notice] = nil
        render
      end

      it "does not render anything" do
        expect(rendered.strip).to be_empty
      end
    end
  end

  describe "alert messages" do
    context "when alert is present" do
      before do
        flash[:alert] = "Error message"
        render
      end

      it "renders the alert message" do
        expect(rendered).to have_content("Error message")
      end

      it "renders flash_message partial with alert type" do
        expect(view).to render_template(partial: "shared/_flash_message")
        expect(rendered).to have_css(".alert.alert-error")
      end
    end

    context "when alert is blank" do
      before do
        flash[:alert] = ""
        render
      end

      it "does not render anything" do
        expect(rendered.strip).to be_empty
      end
    end

    context "when alert is nil" do
      before do
        flash[:alert] = nil
        render
      end

      it "does not render anything" do
        expect(rendered.strip).to be_empty
      end
    end
  end

  describe "both messages present" do
    before do
      flash[:notice] = "Success message"
      flash[:alert] = "Error message"
      render
    end

    it "renders both messages" do
      expect(rendered).to have_content("Success message")
      expect(rendered).to have_content("Error message")
    end

    it "renders both with correct styling" do
      expect(rendered).to have_css(".alert.alert-success")
      expect(rendered).to have_css(".alert.alert-error")
    end
  end

  describe "no messages" do
    before do
      render
    end

    it "renders nothing when no flash messages present" do
      expect(rendered.strip).to be_empty
    end
  end

  describe "HTML safety" do
    context "with HTML content in messages" do
      before do
        flash[:notice] = "<script>alert('xss')</script>Safe message"
        flash[:alert] = "<b>Bold error</b> message"
        render
      end

      it "escapes HTML in notice messages" do
        expect(rendered).to have_content("<script>alert('xss')</script>Safe message")
        expect(rendered).not_to have_css("script")
      end

      it "escapes HTML in alert messages" do
        expect(rendered).to have_content("<b>Bold error</b> message")
        expect(rendered).not_to have_css("b")
      end
    end
  end

  describe "accessibility" do
    before do
      flash[:notice] = "Success message"
      flash[:alert] = "Error message"
      render
    end

    it "includes proper semantic structure" do
      expect(rendered).to have_css("span")
    end

    it "includes descriptive text styling" do
      expect(rendered).to have_css(".alert")
    end

    it "renders icons for visual distinction" do
      expect(view).to render_template(partial: "shared/icons/_notice")
      expect(view).to render_template(partial: "shared/icons/_alert")
    end
  end

  describe "responsive design" do
    before do
      flash[:notice] = "Test message"
      render
    end

    it "includes responsive spacing" do
      expect(rendered).to have_css(".mb-6")
    end

    it "includes flexible layout classes" do
      expect(rendered).to have_css("svg")
      expect(rendered).to have_css("span")
    end
  end

  describe "message truncation" do
    context "with very long messages" do
      let(:long_message) { "This is a very long message that should test how the flash message component handles lengthy content without breaking the layout or causing display issues." * 3 }

      before do
        flash[:notice] = long_message
        render
      end

      it "displays long messages without breaking layout" do
        expect(rendered).to have_content(long_message)
        expect(rendered).to have_css(".alert")
      end
    end
  end

  describe "special characters and encoding" do
    before do
      flash[:notice] = "Message with émojis 🎉 and spéciál characters"
      flash[:alert] = "Error with 'quotes' and \"double quotes\""
      render
    end

    it "properly handles special characters in notices" do
      expect(rendered).to have_content("Message with émojis 🎉 and spéciál characters")
    end

    it "properly handles quotes in alerts" do
      expect(rendered).to have_content("Error with 'quotes' and \"double quotes\"")
    end
  end

  describe "integration with Turbo Streams" do
    before do
      flash[:notice] = "Turbo update successful"
      render
    end

    it "creates HTML compatible with Turbo Stream updates" do
      parsed_html = Nokogiri::HTML(rendered)
      flash_div = parsed_html.css(".alert").first

      expect(flash_div).to be_present
      expect(flash_div['class']).to include("alert-success")
    end

    it "maintains proper structure for dynamic updates" do
      expect(rendered).to have_css(".alert svg")
      expect(rendered).to have_css(".alert span")
    end
  end
end
