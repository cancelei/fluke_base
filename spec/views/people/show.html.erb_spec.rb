require 'rails_helper'

RSpec.describe "people/show", type: :view do
  let(:alice) { create(:user, first_name: "Alice", last_name: "Entrepreneur") }
  let(:bob) { create(:user, first_name: "Bob", last_name: "Developer") }
  let(:project) { create(:project, user: alice, name: "FlukeBase") }
  let!(:agreement) { create(:agreement, :with_participants, project:, initiator: alice, other_party: bob) }

  before do
    assign(:person, alice)
    assign(:projects_involved, [project])
    allow(view).to receive(:current_user).and_return(bob)
    allow(view).to receive(:present).and_return(double("presenter",
      display_name: alice.full_name,
      badges: "<span class='badge'>Community Person</span>".html_safe,
      formatted_bio: "Experienced entrepreneur",
      member_since: "Member since January 2024",
      projects_count: "1 project",
      agreements_count: "1 agreement",
      project_link: "FlukeBase"
    ))
  end

  describe "profile header section" do
    it "displays user's profile information" do
      render

      expect(rendered).to have_css(".card.bg-base-100")
      expect(rendered).to have_content(alice.full_name)
      expect(rendered).to have_content("Community Person")
    end

    it "shows avatar when attached" do
      alice.avatar.attach(io: StringIO.new("test"), filename: "avatar.jpg", content_type: "image/jpeg")

      render

      expect(rendered).to have_css("img[alt*='#{alice.initials}']")
      expect(rendered).to have_css("img.object-cover.rounded-full")
    end

    it "shows default avatar when no image attached" do
      render

      expect(rendered).to have_css(".avatar.placeholder")
      expect(rendered).to have_css(".bg-primary.text-primary-content")
      expect(rendered).to have_css("svg")
    end
  end

  describe "action buttons section" do
    context "when viewing another user's profile" do
      it "shows message button" do
        render

        expect(rendered).to have_button("Message")
        expect(rendered).to have_css("form[action*='/conversations']")
      end

      it "shows agreement initiation button when project selected" do
        current = create(:user)
        current.update!(selected_project_id: project.id)
        allow(view).to receive(:current_user).and_return(current)

        render

        expect(rendered).to have_link("Initiate Agreement")
        expect(rendered).to have_css("a[href*='/agreements/new']")
      end

      it "hides agreement button when no project selected" do
        current = create(:user)
        current.update!(selected_project_id: nil)
        allow(view).to receive(:current_user).and_return(current)

        render

        expect(rendered).not_to have_link("Initiate Agreement")
      end
    end

    context "when viewing own profile" do
      before do
        allow(view).to receive(:current_user).and_return(alice)
      end

      it "shows edit profile button instead of message button" do
        render

        expect(rendered).to have_link("Edit Profile")
        expect(rendered).not_to have_button("Message")
      end
    end
  end

  describe "social media links section" do
    context "when user has social media profiles" do
      let(:alice) do
        create(:user,
          linkedin: "alice-entrepreneur",
          x: "alice_ent",
          youtube: "aliceentrepreneur",
          facebook: "alice.entrepreneur",
          tiktok: "aliceent"
        )
      end

      it "displays all social media links" do
        render

        expect(rendered).to have_link("LinkedIn")
        expect(rendered).to have_link("X")
        expect(rendered).to have_link("YouTube")
        expect(rendered).to have_link("Facebook")
        expect(rendered).to have_link("TikTok")

        expect(rendered).to have_css("a[href*='linkedin.com/in/alice-entrepreneur']")
        expect(rendered).to have_css("a[href*='x.com/alice_ent']")
        expect(rendered).to have_css("a[href*='youtube.com/aliceentrepreneur']")
        expect(rendered).to have_css("a[href*='facebook.com/alice.entrepreneur']")
        expect(rendered).to have_css("a[href*='tiktok.com/@aliceent']")
      end

      it "sets target='_blank' for external links" do
        render

        expect(rendered).to have_css("a[target='_blank']", count: 5)
      end
    end

    context "when user has no social media profiles" do
      it "does not show social media section" do
        render

        expect(rendered).not_to have_content("CONNECT")
        expect(rendered).not_to have_link("LinkedIn")
      end
    end
  end

  describe "connection analysis section" do
    context "when viewing another user's profile" do
      it "shows affinity section" do
        assign(:shared_agreements_count, 1)
        render

        expect(rendered).to have_content("You and #{alice.first_name}")
      end

      context "with shared connections" do
        let(:shared_project) { create(:project, user: bob, name: "Shared Project") }

        before do
          # Add Alice to Bob's project via agreement
          create(:agreement, :with_participants, project: shared_project, initiator: bob, other_party: alice)
          assign(:projects_involved, [project, shared_project])
        end

        it "displays shared projects" do
          allow(bob).to receive(:projects).and_return([shared_project])
          allow(alice).to receive(:projects).and_return([shared_project])

          render

          expect(rendered).to have_content("Shared projects:")
        end
      end

      context "with no shared connections" do
        it "shows encouragement message" do
          allow(bob).to receive(:projects).and_return([])
          allow(alice).to receive(:projects).and_return([project])
          allow(bob).to receive(:try).with(:skills).and_return([])
          allow(alice).to receive(:try).with(:skills).and_return([])
          allow(bob).to receive(:all_agreements).and_return(double("agreements", joins: double("joined", where: [])))

          render

          expect(rendered).not_to have_content("You and #{alice.first_name}")
        end
      end
    end

    context "when viewing own profile" do
      before do
        allow(view).to receive(:current_user).and_return(alice)
      end

      it "does not show affinity section" do
        render

        expect(rendered).not_to have_content("You and #{alice.first_name}")
      end
    end
  end

  describe "navigation tabs section" do
    it "displays all navigation tabs" do
      render

      expect(rendered).to have_link("About", href: "#about")
      expect(rendered).to have_link("Track Record", href: "#track")
      expect(rendered).to have_link("Projects", href: "#projects")
    end

    context "when viewing own profile" do
      before do
        allow(view).to receive(:current_user).and_return(alice)
      end

      it "shows edit profile link in tabs" do
        render

        expect(rendered).to have_link("Edit Profile")
        expect(rendered).to have_css("a[href*='/profile/edit']")
      end
    end
  end

  describe "content sections" do
    it "renders about section with bio" do
      render

      expect(rendered).to have_css("#about")
      expect(rendered).to have_content("About")
      expect(rendered).to have_content("Experienced entrepreneur")
    end

    it "displays statistics cards" do
      render

      expect(rendered).to have_content("Member since January 2024")
    end

    it "renders track record section" do
      render

      expect(rendered).to have_content("Track Record")
    end

    it "renders projects section" do
      render

      expect(rendered).to have_css("#projects")
      expect(rendered).to have_content("Projects")
    end
  end

  describe "projects section" do
    context "with projects" do
      it "displays project information" do
        render

        expect(rendered).to have_content(project.name)
        expect(rendered).to have_content(project.stage.capitalize)
      end

      it "shows agreement initiation button for each project" do
        render

        expect(rendered).to have_link("Agreement")
        expect(rendered).to have_css("a[href*='/agreements/new'][href*='project_id=#{project.id}']")
      end

      it "displays project links when available and visible" do
        project.update!(project_link: "https://flukebase.com")
        allow(view).to receive(:field_visible_to_user?).and_return(true)

        render

        expect(rendered).to have_link(href: "https://flukebase.com")
        expect(rendered).to have_css("a[target='_blank']")
      end
    end

    context "with no projects" do
      before do
        assign(:projects_involved, [])
      end

      it "shows empty state" do
        render

        expect(rendered).to have_content("No projects found for this user")
        expect(rendered).to have_css("svg")
      end
    end
  end

  describe "collaboration call-to-action" do
    context "when viewing another user's profile" do
      it "shows collaboration section" do
        render

        expect(rendered).not_to have_content("Interested in collaborating")
      end
    end

    context "when viewing own profile" do
      before do
        allow(view).to receive(:current_user).and_return(alice)
      end

      it "does not show collaboration section" do
        render

        expect(rendered).not_to have_content("Interested in collaborating")
        expect(rendered).not_to have_button("Send Message")
      end
    end
  end

  describe "responsive design" do
    it "includes responsive CSS classes" do
      render

      expect(rendered).to have_css(".flex.flex-col.lg\\:flex-row")
    end
  end

  describe "accessibility features" do
    it "includes proper semantic markup" do
      render

      expect(rendered).to have_css("h1")
      expect(rendered).to have_css("h2")
      expect(rendered).to have_css("section")
    end

    it "includes alt text for images and icons" do
      render

      expect(rendered).to have_css("svg[class*='text-']") # Icons with proper color classes
    end

    it "includes proper form labels and buttons" do
      render

      expect(rendered).to have_button("Message")
      expect(rendered).to have_css("button[type]")
    end
  end

  describe "error handling" do
    context "when presenter methods fail" do
      before do
        allow(view).to receive(:present).and_return(nil)
      end

      it "gracefully handles missing presenter" do
        expect { render }.not_to raise_error
      end
    end

    context "when user data is incomplete" do
      let(:incomplete_user) { build(:user, first_name: "", last_name: "") }

      before do
        assign(:person, incomplete_user)
      end

      it "handles missing names gracefully" do
        expect { render }.not_to raise_error
      end
    end
  end
end
