# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgreementPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin) { create(:user, admin: true) }
  let(:project_owner) { create(:user) }
  let(:project) { create(:project, user: project_owner) }
  let(:other_user) { create(:user) }

  # Helper to create agreement with participants
  def create_agreement_with_participants(project:, initiator:, other_party:, status: 'Pending')
    agreement = create(:agreement, project: project, status: status)
    create(:agreement_participant, agreement: agreement, user: initiator, is_initiator: true, accept_or_counter_turn_id: other_party.id)
    create(:agreement_participant, agreement: agreement, user: other_party, is_initiator: false, accept_or_counter_turn_id: other_party.id)
    agreement
  end

  describe 'permissions' do
    let(:agreement) { create_agreement_with_participants(project: project, initiator: project_owner, other_party: user) }

    context 'for a visitor (not signed in)' do
      permissions :index?, :show?, :create?, :new? do
        it { expect(subject).not_to permit(nil, agreement) }
      end
    end

    context 'for an admin' do
      permissions :show?, :update?, :edit?, :destroy? do
        it { expect(subject).to permit(admin, agreement) }
      end

      permissions :view_full_details?, :view_counter_offers?, :view_meetings? do
        it { expect(subject).to permit(admin, agreement) }
      end

      permissions :cancel?, :complete? do
        it { expect(subject).to permit(admin, agreement) }
      end
    end

    context 'for the agreement initiator' do
      permissions :show?, :view_full_details? do
        it { expect(subject).to permit(project_owner, agreement) }
      end

      permissions :update?, :edit? do
        it 'allows editing pending agreements' do
          expect(subject).to permit(project_owner, agreement)
        end

        it 'denies editing accepted agreements' do
          accepted_agreement = create_agreement_with_participants(
            project: project,
            initiator: project_owner,
            other_party: user,
            status: 'Accepted'
          )
          expect(subject).not_to permit(project_owner, accepted_agreement)
        end
      end

      permissions :destroy? do
        it 'allows deleting pending agreements' do
          expect(subject).to permit(project_owner, agreement)
        end

        it 'denies deleting accepted agreements' do
          accepted_agreement = create_agreement_with_participants(
            project: project,
            initiator: project_owner,
            other_party: user,
            status: 'Accepted'
          )
          expect(subject).not_to permit(project_owner, accepted_agreement)
        end
      end

      permissions :complete? do
        it 'denies completing pending agreements' do
          expect(subject).not_to permit(project_owner, agreement)
        end

        it 'allows completing active agreements' do
          active_agreement = create_agreement_with_participants(
            project: project,
            initiator: project_owner,
            other_party: user,
            status: 'Accepted'
          )
          expect(subject).to permit(project_owner, active_agreement)
        end
      end
    end

    context 'for the other party' do
      permissions :show?, :view_full_details? do
        it { expect(subject).to permit(user, agreement) }
      end

      permissions :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(user, agreement) }
      end

      permissions :accept? do
        it 'allows accepting when it is their turn' do
          # The agreement is set up with other_party's turn
          expect(subject).to permit(user, agreement)
        end

        it 'denies accepting when not their turn' do
          agreement_not_turn = create_agreement_with_participants(
            project: project,
            initiator: project_owner,
            other_party: user
          )
          # Change turn to initiator
          agreement_not_turn.agreement_participants.update_all(accept_or_counter_turn_id: project_owner.id)
          expect(subject).not_to permit(user, agreement_not_turn)
        end
      end

      permissions :reject? do
        it 'allows rejecting when it is their turn' do
          expect(subject).to permit(user, agreement)
        end
      end

      permissions :cancel? do
        it 'allows canceling pending agreements' do
          expect(subject).to permit(user, agreement)
        end

        it 'allows canceling active agreements' do
          active_agreement = create_agreement_with_participants(
            project: project,
            initiator: project_owner,
            other_party: user,
            status: 'Accepted'
          )
          expect(subject).to permit(user, active_agreement)
        end
      end
    end

    context 'for an unrelated user' do
      permissions :show?, :update?, :edit?, :destroy? do
        it { expect(subject).not_to permit(other_user, agreement) }
      end

      permissions :accept?, :reject?, :counter?, :cancel?, :complete? do
        it { expect(subject).not_to permit(other_user, agreement) }
      end

      permissions :view_full_details?, :view_counter_offers? do
        it { expect(subject).not_to permit(other_user, agreement) }
      end
    end

    context 'for viewing permissions' do
      let(:active_agreement) do
        create_agreement_with_participants(
          project: project,
          initiator: project_owner,
          other_party: user,
          status: 'Accepted'
        )
      end

      permissions :view_meetings? do
        it 'allows participants to view meetings on active agreements' do
          expect(subject).to permit(user, active_agreement)
          expect(subject).to permit(project_owner, active_agreement)
        end

        it 'denies viewing meetings on pending agreements' do
          expect(subject).not_to permit(user, agreement)
        end
      end

      permissions :view_time_logs?, :view_github_logs? do
        it 'allows participants to view on active agreements' do
          expect(subject).to permit(user, active_agreement)
          expect(subject).to permit(project_owner, active_agreement)
        end

        it 'allows participants to view on completed agreements' do
          completed_agreement = create_agreement_with_participants(
            project: project,
            initiator: project_owner,
            other_party: user,
            status: 'Completed'
          )
          expect(subject).to permit(user, completed_agreement)
        end

        it 'denies viewing on pending agreements' do
          expect(subject).not_to permit(user, agreement)
        end
      end
    end
  end

  describe 'Scope' do
    let!(:user_initiated_agreement) do
      create_agreement_with_participants(project: project, initiator: user, other_party: project_owner)
    end

    let!(:user_received_agreement) do
      create_agreement_with_participants(project: project, initiator: project_owner, other_party: user)
    end

    let!(:other_agreement) do
      create_agreement_with_participants(project: project, initiator: project_owner, other_party: other_user)
    end

    context 'for a visitor' do
      it 'returns no agreements' do
        scope = Pundit.policy_scope!(nil, Agreement)
        expect(scope).to be_empty
      end
    end

    context 'for an admin' do
      it 'returns all agreements' do
        scope = Pundit.policy_scope!(admin, Agreement)
        expect(scope.count).to eq(Agreement.count)
      end
    end

    context 'for a user' do
      it 'returns only agreements they are participants in' do
        scope = Pundit.policy_scope!(user, Agreement)
        expect(scope).to include(user_initiated_agreement)
        expect(scope).to include(user_received_agreement)
        expect(scope).not_to include(other_agreement)
      end
    end
  end
end
