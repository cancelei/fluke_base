# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'github_logs/_empty_state.html.erb', type: :view do
  let(:project) { create(:project, name: 'Test Project') }
  let(:current_user) { create(:user, :alice) }

  before do
    allow(view).to receive(:current_user).and_return(current_user)
  end

  describe 'basic empty state structure' do
    before { render 'github_logs/empty_state', project: }

    it 'displays empty state with proper styling' do
      expect(rendered).to have_css('.px-6.py-12.text-center')
    end

    it 'shows appropriate empty state icon' do
      expect(rendered).to have_css('svg.mx-auto.h-16.w-16')
      expect(rendered).to have_css('svg.text-base-content\/40')
    end

    it 'displays empty state heading and message' do
      expect(rendered).to have_content('No GitHub activity found')
      expect(rendered).to have_css('h3.text-lg.font-medium')
    end
  end

  describe 'contextual messaging' do
    context 'for project owner' do
      let(:project) { create(:project, user: current_user) }

      before { render 'github_logs/empty_state', project: }

      it 'displays owner-specific empty state message' do
        expect(rendered).to have_content('The repository might be empty or there was an issue accessing it')
      end

      it 'provides troubleshooting guidance' do
        expect(rendered).to have_content('Make sure:')
        expect(rendered).to have_content('The repository URL is correctly set')
        expect(rendered).to have_content('You have the necessary permissions')
        expect(rendered).to have_content('The repository has at least one commit')
      end

      it 'displays troubleshooting list' do
        expect(rendered).to have_css('ul.list-disc')
        expect(rendered).to have_css('li', count: 3)
      end
    end

    context 'for collaborator with active agreement' do
      let(:agreement) { create(:agreement, project:, status: Agreement::ACCEPTED) }
      let!(:agreement_participant) { create(:agreement_participant, agreement:, user: current_user) }

      before do
        allow(project).to receive(:agreements).and_return(double('agreements',
          active: double('active_agreements',
            joins: double('joined_agreements',
              exists?: true
            )
          )
        ))
        render 'github_logs/empty_state', project:
      end

      it 'displays collaborator-specific message' do
        expect(rendered).to have_content('The repository might be empty or there was an issue accessing it')
      end

      it 'provides troubleshooting guidance for collaborators' do
        expect(rendered).to have_content('Make sure:')
        expect(rendered).to have_content('repository URL')
        expect(rendered).to have_content('permissions')
      end
    end

    context 'for non-collaborator users' do
      before { render 'github_logs/empty_state', project: }

      it 'displays general empty state message' do
        expect(rendered).to have_content("doesn't have any GitHub activity yet or the repository is not properly configured")
      end

      it 'does not show troubleshooting steps' do
        expect(rendered).not_to have_content('Make sure:')
        expect(rendered).not_to have_css('ul.list-disc')
      end
    end

    context 'in job context' do
      before { render 'github_logs/empty_state', project:, job_context: true }

      it 'displays job-specific empty state message' do
        expect(rendered).to have_content("doesn't have any GitHub activity yet or the repository is not properly configured")
      end

      it 'does not show user-specific troubleshooting' do
        expect(rendered).not_to have_content('Make sure:')
      end
    end
  end

  describe 'accessibility features' do
    before { render 'github_logs/empty_state', project: }

    it 'provides semantic content structure' do
      expect(rendered).to have_css('h3') # Proper heading
      expect(rendered).to have_css('p') # Descriptive text
    end

    it 'uses appropriate heading hierarchy' do
      expect(rendered).to have_css('h3.text-lg.font-medium')
    end

    it 'maintains readable color contrast' do
      expect(rendered).to include('text-base-content')
    end

    it 'provides meaningful SVG for screen readers' do
      expect(rendered).to have_css('svg') # Icon present
      # SVG should be decorative or have appropriate labeling
    end
  end

  describe 'responsive design' do
    before { render 'github_logs/empty_state', project: }

    it 'uses responsive spacing and layout' do
      expect(rendered).to include('px-6 py-12') # Responsive padding
      expect(rendered).to include('text-center') # Centered alignment
      expect(rendered).to include('mx-auto') # Auto margins
    end

    it 'maintains proper text sizing across devices' do
      expect(rendered).to include('text-lg') # Large, readable heading
      expect(rendered).to include('text-sm') # Appropriately sized body text
    end

    it 'uses flexible width constraints' do
      expect(rendered).to include('max-w-2xl') # Content width constraint
      expect(rendered).to include('max-w-md') # List width constraint
    end
  end

  describe 'troubleshooting guidance styling' do
    let(:project) { create(:project, user: current_user) }

    before { render 'github_logs/empty_state', project: }

    it 'styles troubleshooting section appropriately' do
      expect(rendered).to have_css('.text-sm.text-base-content\/60')
      expect(rendered).to have_css('.list-disc.text-left')
      expect(rendered).to have_css('.space-y-1')
    end

    it 'provides proper list formatting' do
      expect(rendered).to have_css('ul.list-disc')
      expect(rendered).to have_css('li')
    end

    it 'centers troubleshooting content' do
      expect(rendered).to have_css('.max-w-md.mx-auto')
    end
  end

  describe 'conditional rendering logic' do
    context 'with current_user defined' do
      before { render 'github_logs/empty_state', project: }

      it 'checks for current_user availability' do
        # Should handle current_user being defined
        expect(rendered).to be_present
      end
    end

    context 'without current_user defined' do
      before do
        allow(view).to receive(:current_user).and_return(nil)
      end

      it 'handles missing current_user gracefully' do
        expect { render 'github_logs/empty_state', project: }.not_to raise_error
      end
    end

    context 'with job_context parameter' do
      before { render 'github_logs/empty_state', project:, job_context: true }

      it 'uses job-specific messaging' do
        expect(rendered).to have_content("doesn't have any GitHub activity yet")
        expect(rendered).not_to have_content('Make sure:')
      end
    end

    context 'without job_context parameter' do
      before { render 'github_logs/empty_state', project: }

      it 'uses default user-facing messaging' do
        expect(rendered).to have_content("doesn't have any GitHub activity yet")
      end
    end
  end

  describe 'permission-based messaging' do
    context 'when user is project owner' do
      let(:project) { create(:project, user: current_user) }

      before { render 'github_logs/empty_state', project: }

      it 'shows actionable troubleshooting steps' do
        expect(rendered).to have_content('repository URL is correctly set')
        expect(rendered).to have_content('necessary permissions')
        expect(rendered).to have_content('at least one commit')
      end
    end

    context 'when user has active agreement' do
      before do
        allow(project).to receive(:agreements).and_return(
          double('agreements',
            active: double('active_agreements',
              joins: double('joined_agreements', exists?: true)
            )
          )
        )
        render 'github_logs/empty_state', project:
      end

      it 'shows collaborator-appropriate guidance' do
        expect(rendered).to have_content('Make sure:')
        expect(rendered).to have_content('repository URL')
      end
    end

    context 'when user is not owner or collaborator' do
      before { render 'github_logs/empty_state', project: }

      it 'shows general informational message' do
        expect(rendered).not_to have_content('Make sure:')
        expect(rendered).to have_content("doesn't have any GitHub activity yet")
      end
    end
  end

  describe 'visual hierarchy and layout' do
    before { render 'github_logs/empty_state', project: }

    it 'maintains proper visual hierarchy' do
      expect(rendered).to have_css('h3.mt-4') # Heading positioned after icon
      expect(rendered).to have_css('p.mt-2') # Description follows heading
    end

    it 'uses appropriate spacing between elements' do
      expect(rendered).to include('mt-4') # Space after icon
      expect(rendered).to include('mt-2') # Space after heading
      expect(rendered).to include('mb-2') # Space before list
    end

    it 'centers content appropriately' do
      expect(rendered).to have_css('.text-center') # Main container
      expect(rendered).to have_css('.mx-auto') # Icon centering
    end
  end
end
