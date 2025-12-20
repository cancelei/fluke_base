# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectMembershipPolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, admin: true) }
  let(:project_owner) { create(:user) }
  let(:project) { create(:project, user: project_owner) }
  let(:other_user) { create(:user) }

  # Helper to create membership
  def create_membership(project:, user:, role:, accepted: true)
    create(:project_membership,
           project:,
           user:,
           role:,
           accepted_at: accepted ? Time.current : nil)
  end

  describe 'permissions' do
    let(:member_user) { create(:user) }
    let(:membership) { create_membership(project:, user: member_user, role: 'member') }

    context 'for a visitor (not signed in)' do
      permissions :index?, :show?, :create?, :new?, :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(nil, membership) }
      end
    end

    context 'for an admin' do
      permissions :show?, :create?, :new?, :update?, :edit?, :destroy? do
        it { expect(subject).to permit(admin, membership) }
      end

      permissions :accept?, :change_role?, :resend_invitation? do
        it { expect(subject).to permit(admin, membership) }
      end
    end

    context 'for the project owner' do
      permissions :show?, :create?, :new? do
        it { expect(subject).to permit(project_owner, membership) }
      end

      permissions :update?, :edit?, :destroy? do
        it 'allows managing member roles' do
          expect(subject).to permit(project_owner, membership)
        end

        it 'denies modifying owner role' do
          owner_membership = create_membership(project:, user: other_user, role: 'owner')
          expect(subject).not_to permit(project_owner, owner_membership)
        end
      end

      permissions :change_role? do
        it { expect(subject).to permit(project_owner, membership) }
      end
    end

    context 'for a project admin (via membership)' do
      let(:admin_user) { create(:user) }

      before do
        create_membership(project:, user: admin_user, role: 'admin')
      end

      permissions :create?, :new? do
        it { expect(subject).to permit(admin_user, membership) }
      end

      permissions :update?, :edit? do
        it 'allows updating lower-role members' do
          expect(subject).to permit(admin_user, membership)
        end

        it 'denies updating owner' do
          owner_membership = create_membership(project:, user: other_user, role: 'owner')
          expect(subject).not_to permit(admin_user, owner_membership)
        end

        it 'denies updating other admins' do
          other_admin_membership = create_membership(project:, user: other_user, role: 'admin')
          expect(subject).not_to permit(admin_user, other_admin_membership)
        end
      end

      permissions :destroy? do
        it 'allows removing lower-role members' do
          expect(subject).to permit(admin_user, membership)
        end

        it 'denies removing owner' do
          owner_membership = create_membership(project:, user: project_owner, role: 'owner')
          expect(subject).not_to permit(admin_user, owner_membership)
        end
      end
    end

    context 'for the membership owner (self)' do
      permissions :show? do
        it { expect(subject).to permit(member_user, membership) }
      end

      permissions :accept? do
        it 'allows accepting their own pending invitation' do
          pending_membership = create_membership(project:, user: member_user, role: 'member', accepted: false)
          expect(subject).to permit(member_user, pending_membership)
        end

        it 'denies accepting already accepted membership' do
          expect(subject).not_to permit(member_user, membership)
        end
      end

      permissions :destroy? do
        it 'allows removing themselves from project' do
          expect(subject).to permit(member_user, membership)
        end

        it 'denies owner from removing themselves' do
          owner_membership = create_membership(project:, user: project_owner, role: 'owner')
          expect(subject).not_to permit(project_owner, owner_membership)
        end
      end

      permissions :update?, :edit?, :create?, :new? do
        it { expect(subject).not_to permit(member_user, membership) }
      end
    end

    context 'for an unrelated user' do
      permissions :show?, :create?, :new?, :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(other_user, membership) }
      end

      permissions :accept?, :change_role?, :resend_invitation? do
        it { expect(subject).not_to permit(other_user, membership) }
      end
    end

    context 'for pending invitations' do
      let(:pending_membership) { create_membership(project:, user: member_user, role: 'member', accepted: false) }

      permissions :resend_invitation? do
        it 'allows project admins to resend' do
          expect(subject).to permit(project_owner, pending_membership)
        end

        it 'denies resending for accepted memberships' do
          expect(subject).not_to permit(project_owner, membership)
        end
      end
    end
  end

  describe 'Scope' do
    let(:user) { create(:user) }
    let!(:user_own_membership) { create_membership(project:, user:, role: 'member') }
    let!(:other_project) { create(:project) }
    let!(:other_membership) { create_membership(project: other_project, user: other_user, role: 'member') }

    # Create project where user is admin
    let!(:admin_project) { create(:project) }
    let!(:admin_membership) { create_membership(project: admin_project, user:, role: 'admin') }
    let!(:admin_project_other_membership) { create_membership(project: admin_project, user: other_user, role: 'member') }

    context 'for a visitor' do
      it 'returns no memberships' do
        scope = Pundit.policy_scope!(nil, ProjectMembership)
        expect(scope).to be_empty
      end
    end

    context 'for an admin' do
      it 'returns all memberships' do
        scope = Pundit.policy_scope!(admin, ProjectMembership)
        expect(scope.count).to eq(ProjectMembership.count)
      end
    end

    context 'for a regular user' do
      it 'returns their own memberships and memberships for projects they admin' do
        scope = Pundit.policy_scope!(user, ProjectMembership)
        expect(scope).to include(user_own_membership)
        expect(scope).to include(admin_membership)
        expect(scope).to include(admin_project_other_membership)
        expect(scope).not_to include(other_membership)
      end
    end
  end
end
