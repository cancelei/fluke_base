# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MeetingPolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, admin: true) }
  let(:project_owner) { create(:user) }
  let(:project) { create(:project, user: project_owner) }
  let(:participant_user) { create(:user) }
  let(:other_user) { create(:user) }

  # Helper to create agreement with participants
  def create_agreement_with_participants(project:, initiator:, other_party:, status: 'Accepted')
    agreement = create(:agreement, project:, status:)
    create(:agreement_participant, agreement:, user: initiator, is_initiator: true)
    create(:agreement_participant, agreement:, user: other_party, is_initiator: false)
    agreement
  end

  describe 'permissions' do
    let(:agreement) do
      create_agreement_with_participants(
        project:,
        initiator: project_owner,
        other_party: participant_user,
        status: 'Accepted'
      )
    end
    let(:meeting) { create(:meeting, agreement:) }

    context 'for a visitor (not signed in)' do
      permissions :index?, :show?, :create?, :new?, :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(nil, meeting) }
      end
    end

    context 'for an admin' do
      permissions :show?, :create?, :new?, :update?, :edit?, :destroy? do
        it { expect(subject).to permit(admin, meeting) }
      end
    end

    context 'for an agreement participant' do
      permissions :show? do
        it 'allows both participants to view meetings' do
          expect(subject).to permit(project_owner, meeting)
          expect(subject).to permit(participant_user, meeting)
        end
      end

      permissions :create?, :new? do
        it 'allows participants to create meetings on active agreements' do
          expect(subject).to permit(project_owner, meeting)
          expect(subject).to permit(participant_user, meeting)
        end

        it 'denies creating meetings on pending agreements' do
          pending_agreement = create_agreement_with_participants(
            project:,
            initiator: project_owner,
            other_party: participant_user,
            status: 'Pending'
          )
          pending_meeting = build(:meeting, agreement: pending_agreement)
          expect(subject).not_to permit(project_owner, pending_meeting)
        end
      end

      permissions :update?, :edit?, :destroy? do
        it 'allows participants to modify meetings' do
          expect(subject).to permit(project_owner, meeting)
          expect(subject).to permit(participant_user, meeting)
        end
      end
    end

    context 'for an unrelated user' do
      permissions :show?, :create?, :new?, :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(other_user, meeting) }
      end
    end

    context 'for different agreement statuses' do
      let(:pending_agreement) do
        create_agreement_with_participants(
          project:,
          initiator: project_owner,
          other_party: participant_user,
          status: 'Pending'
        )
      end
      let(:pending_meeting) { build(:meeting, agreement: pending_agreement) }

      permissions :create?, :new? do
        it 'denies creating meetings for non-active agreements' do
          expect(subject).not_to permit(project_owner, pending_meeting)
          expect(subject).not_to permit(participant_user, pending_meeting)
        end
      end
    end
  end

  describe 'Scope' do
    let!(:participant_agreement) do
      create_agreement_with_participants(
        project:,
        initiator: project_owner,
        other_party: participant_user
      )
    end

    let!(:other_agreement) do
      create_agreement_with_participants(
        project:,
        initiator: project_owner,
        other_party: other_user
      )
    end

    let!(:participant_meeting) { create(:meeting, agreement: participant_agreement) }
    let!(:other_meeting) { create(:meeting, agreement: other_agreement) }

    context 'for a visitor' do
      it 'returns no meetings' do
        scope = Pundit.policy_scope!(nil, Meeting)
        expect(scope).to be_empty
      end
    end

    context 'for an admin' do
      it 'returns all meetings' do
        scope = Pundit.policy_scope!(admin, Meeting)
        expect(scope.count).to eq(Meeting.count)
      end
    end

    context 'for an agreement participant' do
      it 'returns only meetings for agreements they participate in' do
        scope = Pundit.policy_scope!(participant_user, Meeting)
        expect(scope).to include(participant_meeting)
        expect(scope).not_to include(other_meeting)
      end
    end

    context 'for an unrelated user' do
      it 'returns no meetings' do
        unrelated_user = create(:user)
        scope = Pundit.policy_scope!(unrelated_user, Meeting)
        expect(scope).to be_empty
      end
    end
  end
end
