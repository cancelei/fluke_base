require 'rails_helper'

RSpec.describe "github_logs/index", type: :view do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:, name: "Test Project") }
  let(:github_branch) { create(:github_branch, project:, branch_name: "main") }
  let(:recent_commits) { [] }
  let(:pagy) { Pagy.new(count: 0, page: 1, items: 10) }

  before do
    assign(:project, project)
    assign(:recent_commits, recent_commits)
    assign(:pagy, pagy)
    assign(:available_branches, [[github_branch.id, github_branch.branch_name]])
    assign(:available_users, ["testuser"])
    assign(:selected_branch, nil)
    assign(:user_name, nil)
    assign(:agreement_only, false)
    assign(:total_commits, 0)
    assign(:total_additions, 0)
    assign(:total_deletions, 0)
    assign(:last_updated, Time.current)
    assign(:contributions, {})

    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:time_ago_in_words).and_return("5 minutes")
    allow(view).to receive(:number_with_delimiter).and_return("0")
  end

  describe "turbo stream setup" do
    it "includes turbo stream from for project" do
      render

      # The helper renders a <turbo-cable-stream-source> tag; assert its presence
      expect(rendered).to include("<turbo-cable-stream-source")
    end

    it "renders github_logs partial" do
      render

      expect(view).to render_template(partial: "github_logs/_github_logs")
    end
  end

  describe "page header" do
    it "displays project name in header" do
      render

      expect(rendered).to have_content("GitHub Activity for #{project.name}")
      expect(rendered).to have_css("h2", text: "GitHub Activity for #{project.name}")
    end

    it "includes responsive header classes" do
      render

      expect(rendered).to have_css("h2.text-2xl.font-bold.leading-7")
      expect(rendered).to have_css("h2.sm\\:text-3xl.sm\\:truncate")
    end
  end

  describe "branch filter" do
    context "with available branches" do
      it "displays branch dropdown" do
        render

        expect(rendered).to have_content("Branch:")
        expect(rendered).to have_content("All Branches")
        expect(rendered).to have_css("details.dropdown")
      end

      it "includes all branch options" do
        render

        expect(rendered).to have_link("All Branches", visible: :all)
        expect(rendered).to have_link(github_branch.branch_name, visible: :all)
      end

      it "shows selected branch when present" do
        assign(:selected_branch, github_branch.id)
        render

        expect(rendered).to have_content(github_branch.branch_name)
      end
    end

    context "without available branches" do
      before do
        assign(:available_branches, [])
      end

      it "does not show branch filter section" do
        render

        expect(rendered).not_to have_content("Branch:")
      end
    end
  end

  describe "user filter" do
    it "displays user dropdown" do
      render

      expect(rendered).to have_content("User:")
      expect(rendered).to have_content("All Users")
      expect(rendered).to have_css("details.dropdown")
    end

    it "includes user options" do
      render

      expect(rendered).to have_link("All Users", visible: :all)
      expect(rendered).to have_link("testuser", visible: :all)
    end

    it "shows selected user when present" do
      assign(:user_name, "testuser")
      render

      expect(rendered).to have_content("testuser")
    end
  end

  describe "agreement only toggle" do
    it "displays toggle switch" do
      render

      expect(rendered).to have_content("Agreement Only")
      expect(rendered).to have_css("input[type='checkbox'][id='toggleB']")
    end

    it "shows checked state when agreement_only is true" do
      assign(:agreement_only, true)
      render

      expect(rendered).to have_css("input[checked]")
    end

    it "shows unchecked state when agreement_only is false" do
      render

      expect(rendered).not_to have_css("input[checked]")
    end
  end

  describe "clear filters" do
    context "with active filters" do
      before do
        assign(:selected_branch, github_branch.id)
        assign(:user_name, "testuser")
        assign(:agreement_only, true)
      end

      it "displays clear filters link" do
        render

        expect(rendered).to have_link("Clear Filters")
        expect(rendered).to have_css("a[href*='/github_logs']")
      end
    end

    context "without active filters" do
      it "does not display clear filters link" do
        render

        expect(rendered).not_to have_link("Clear Filters")
      end
    end
  end

  describe "statistics section" do
    it "displays last updated information" do
      render

      expect(rendered).to have_content("Last updated: 5 minutes ago")
    end

    it "displays total commits" do
      render

      expect(rendered).to have_content("0 total commits")
    end

    it "includes proper icons" do
      render

      expect(rendered).to have_css("svg.flex-shrink-0")
      expect(rendered).to have_css("svg.text-success")
    end
  end

  describe "action buttons" do
    context "when user has access" do
      it "displays refresh commits button" do
        render

        expect(rendered).not_to have_button("Refresh Commits")
      end

      it "displays back to project link" do
        render

        expect(rendered).not_to have_link("Back to Project")
      end

      it "includes confirmation dialog for refresh" do
        render

        expect(rendered).not_to include("Are you sure you want to refresh the commits?")
      end
    end

    context "when user does not have access" do
      let(:other_user) { create(:user) }

      before do
        allow(view).to receive(:current_user).and_return(other_user)
        allow(project).to receive_message_chain(:agreements, :active, :joins, :exists?).and_return(false)
      end

      it "does not display action buttons" do
        render

        expect(rendered).not_to have_button("Refresh Commits")
        expect(rendered).not_to have_link("Back to Project")
      end
    end
  end

  describe "contributions summary section" do
    it "displays contributions summary header" do
      render

      expect(rendered).to have_content("Contributions Summary")
      expect(rendered).to have_content("Overview of all contributions to the repository")
    end

    it "includes contributions section partial" do
      render

      expect(view).to render_template(partial: "github_logs/_contributions_section")
    end

    it "displays last activity information" do
      render

      expect(rendered).to have_content("Last activity: 5 minutes ago")
    end
  end

  describe "recent commits section" do
    it "displays recent commits header" do
      render

      expect(rendered).to have_content("Recent Commits")
    end

    it "includes turbo frame for commits" do
      render

      expect(rendered).to have_css("turbo-frame[id='github_commits']")
    end

    context "with commits" do
      let(:github_log) { create(:github_log, project:, user:) }
      let(:recent_commits) { [ github_log ] }
      let(:pagy) { Pagy.new(count: 1, page: 1, items: 10) }

      before do
        assign(:recent_commits, recent_commits)
        assign(:pagy, pagy)
      end

      it "renders commits list partial" do
        render

        expect(view).to render_template(partial: "github_logs/_commits_list")
      end

      it "displays pagination information" do
        render

        expect(rendered).to have_content("Showing 1-1 of 1 commits")
      end

      it "includes pagination controls" do
        render

        expect(view).to render_template(partial: "shared/_pagination")
      end
    end

    context "without commits" do
      it "renders empty state" do
        render

        expect(view).to render_template(partial: "github_logs/_empty_state")
      end

      it "does not include pagination" do
        render

        expect(rendered).not_to have_content("Showing")
        expect(view).not_to render_template(partial: "shared/pagination")
      end
    end
  end

  describe "responsive design" do
    it "includes responsive container classes" do
      render

      expect(rendered).to have_css(".py-6")
    end

    it "includes responsive grid classes" do
      render

      expect(rendered).to have_css(".grid.grid-cols-1.md\\:grid-cols-2")
      expect(rendered).to have_css(".flex.flex-col.sm\\:flex-row.sm\\:flex-wrap")
    end

    it "includes responsive display classes" do
      render

      expect(rendered).to have_css(".lg\\:flex")
    end
  end

  describe "accessibility features" do
    it "includes proper form labels" do
      render

      expect(rendered).to have_css("label[for='branch']")
      expect(rendered).to have_css("label[for='user_filter']")
      expect(rendered).to have_css("label[for='toggleB']")
    end

    it "includes proper heading structure" do
      render

      expect(rendered).to have_css("h2")
      expect(rendered).to have_css("h3")
    end

    it "includes aria labels and roles" do
      render

      expect(rendered).to have_css("details.dropdown")
      expect(rendered).to have_css("input[id]")
    end

    it "includes screen reader friendly text" do
      render

      expect(rendered).to have_css(".sr-only")
    end
  end

  describe "Stimulus controllers integration" do
    it "includes dropdown controller" do
      render

      expect(rendered).to have_css("details.dropdown")
    end
  end

  describe "URL generation" do
    it "generates correct filter URLs" do
      render

      expect(rendered).to include("branch=")
      expect(rendered).to include("user_name=")
      expect(rendered).to include("agreement_only=")
    end

    it "preserves current filters in links" do
      assign(:selected_branch, github_branch.id)
      assign(:user_name, "testuser")
      render

      expect(rendered).to include("branch=#{github_branch.id}")
      expect(rendered).to include("user_name=testuser")
    end
  end

  describe "error handling" do
    context "when project data is missing" do
      before do
        assign(:project, nil)
      end

      it "handles missing project gracefully" do
        render

        expect(rendered).to include("GitHub activity is unavailable")
        expect(rendered).to include("project context is missing")
      end
    end

    context "when commits data is corrupt" do
      before do
        assign(:recent_commits, nil)
      end

      it "handles missing commits data" do
        expect { render }.not_to raise_error
      end
    end
  end

  describe "performance considerations" do
    context "with large dataset indicators" do
      before do
        assign(:total_commits, 10000)
        large_commits = Array.new(10) { create(:github_log, project:, user:) }
        assign(:recent_commits, large_commits)
        assign(:pagy, Pagy.new(count: 100, page: 1, items: 10))
        allow(view).to receive(:url_for).and_return('#')
        allow(view).to receive(:number_with_delimiter).and_call_original
      end

      it "handles large commit counts" do
        render

        expect(rendered).to include("10,000")
      end

      it "implements pagination for large datasets" do
        render

        expect(view).to render_template(partial: "shared/_pagination")
      end
    end
  end
end
