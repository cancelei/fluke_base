# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:project_owner) { create(:user) }
  let(:project) { create(:project, user: project_owner) }
  let(:stealth_project) { create(:project, user: project_owner, stealth_mode: true) }

  # Helper to create membership
  def create_membership(project, user, role)
    create(:project_membership, project: project, user: user, role: role, accepted_at: Time.current)
  end

  # Helper to create agreement
  def create_accepted_agreement(project, user)
    agreement = create(:agreement, project: project, status: 'Accepted')
    create(:agreement_participant, agreement: agreement, user: user, is_initiator: false)
    create(:agreement_participant, agreement: agreement, user: project.user, is_initiator: true)
    agreement
  end

  describe 'permissions' do
    context 'for a visitor (not signed in)' do
      permissions :index?, :create?, :new? do
        it { expect(subject).not_to permit(nil, project) }
      end

      permissions :show? do
        it 'denies access to stealth projects' do
          expect(subject).not_to permit(nil, stealth_project)
        end

        it 'allows access to public projects' do
          expect(subject).to permit(nil, project)
        end
      end

      permissions :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(nil, project) }
      end
    end

    context 'for an admin' do
      permissions :index?, :show?, :create?, :new? do
        it { expect(subject).to permit(admin, project) }
      end

      permissions :update?, :edit?, :destroy? do
        it { expect(subject).to permit(admin, project) }
      end

      permissions :manage_team?, :invite_member?, :remove_member? do
        it { expect(subject).to permit(admin, project) }
      end

      permissions :view_github_logs?, :access_repository? do
        it { expect(subject).to permit(admin, project) }
      end
    end

    context 'for the project owner' do
      permissions :show?, :update?, :edit?, :destroy? do
        it { expect(subject).to permit(project_owner, project) }
      end

      permissions :manage_team?, :invite_member?, :remove_member? do
        it { expect(subject).to permit(project_owner, project) }
      end

      permissions :toggle_stealth_mode?, :view_sensitive_fields? do
        it { expect(subject).to permit(project_owner, project) }
      end
    end

    context 'for a project admin (via membership)' do
      let(:admin_member) { create(:user) }

      before do
        create_membership(project, admin_member, 'admin')
      end

      permissions :show?, :update?, :edit? do
        it { expect(subject).to permit(admin_member, project) }
      end

      permissions :destroy? do
        it { expect(subject).not_to permit(admin_member, project) }
      end

      permissions :manage_team?, :invite_member?, :remove_member? do
        it { expect(subject).to permit(admin_member, project) }
      end

      permissions :toggle_stealth_mode?, :view_sensitive_fields? do
        it { expect(subject).not_to permit(admin_member, project) }
      end
    end

    context 'for a project member (via membership)' do
      let(:member) { create(:user) }

      before do
        create_membership(project, member, 'member')
      end

      permissions :show?, :view_milestones? do
        it { expect(subject).to permit(member, project) }
      end

      permissions :manage_milestones? do
        it { expect(subject).to permit(member, project) }
      end

      permissions :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(member, project) }
      end

      permissions :manage_team?, :invite_member?, :remove_member? do
        it { expect(subject).not_to permit(member, project) }
      end
    end

    context 'for a user with an active agreement' do
      let(:agreement_user) { create(:user) }

      before do
        create_accepted_agreement(project, agreement_user)
      end

      permissions :show?, :view_milestones? do
        it { expect(subject).to permit(agreement_user, project) }
      end

      permissions :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(agreement_user, project) }
      end

      permissions :manage_team? do
        it { expect(subject).not_to permit(agreement_user, project) }
      end
    end

    context 'for an unrelated user' do
      permissions :show? do
        it 'allows viewing public projects' do
          expect(subject).to permit(user, project)
        end

        it 'denies viewing stealth projects' do
          expect(subject).not_to permit(user, stealth_project)
        end
      end

      permissions :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(user, project) }
      end

      permissions :manage_team?, :invite_member?, :remove_member? do
        it { expect(subject).not_to permit(user, project) }
      end
    end
  end

  describe 'Scope' do
    let!(:user_project) { create(:project, user: user) }
    let!(:public_project) { create(:project, stealth_mode: false) }
    let!(:stealth_project) { create(:project, stealth_mode: true) }
    let!(:member_project) { create(:project) }
    let!(:agreement_project) { create(:project) }

    before do
      create_membership(member_project, user, 'member')
      create_accepted_agreement(agreement_project, user)
    end

    context 'for a visitor' do
      it 'returns only public projects' do
        scope = Pundit.policy_scope!(nil, Project)
        expect(scope).to include(public_project)
        expect(scope).not_to include(stealth_project)
      end
    end

    context 'for an admin' do
      it 'returns all projects' do
        scope = Pundit.policy_scope!(admin, Project)
        expect(scope.count).to eq(Project.count)
      end
    end

    context 'for a regular user' do
      it 'returns their own projects, member projects, agreement projects, and public projects' do
        scope = Pundit.policy_scope!(user, Project)
        expect(scope).to include(user_project)
        expect(scope).to include(public_project)
        expect(scope).to include(member_project)
        expect(scope).to include(agreement_project)
        expect(scope).not_to include(stealth_project)
      end
    end
  end
end
