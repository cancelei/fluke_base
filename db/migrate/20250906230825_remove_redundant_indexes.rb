class RemoveRedundantIndexes < ActiveRecord::Migration[8.0]
  def change
    # Remove redundant indexes identified by active_record_doctor
    # These indexes are redundant because they are covered by other more specific indexes

    # GitHub related redundant indexes
    remove_index :github_branch_logs, name: :index_github_branch_logs_on_github_branch_id, if_exists: true
    remove_index :github_logs, name: :index_github_logs_on_project_commit_sha, if_exists: true
    remove_index :github_logs, name: :index_github_logs_on_project_id, if_exists: true
    remove_index :github_logs, name: :index_github_logs_on_project_id_and_commit_sha, if_exists: true
    remove_index :github_branches, name: :index_github_branches_on_project_id, if_exists: true

    # Agreement related redundant indexes
    remove_index :agreement_participants, name: :idx_agreement_participants_on_turn, if_exists: true
    remove_index :agreement_participants, name: :index_agreement_participants_on_accept_or_counter_turn_id, if_exists: true
    remove_index :agreement_participants, name: :index_agreement_participants_on_agreement_id, if_exists: true

    # Blockchain related redundant indexes
    remove_index :blockchain_wallets, name: :index_blockchain_wallets_on_user_id, if_exists: true
    remove_index :escrow_contracts, name: :index_escrow_contracts_on_agreement_id, if_exists: true
    remove_index :escrow_milestones, name: :index_escrow_milestones_on_escrow_contract_id, if_exists: true
    remove_index :escrow_milestones, name: :index_escrow_milestones_on_milestone_id, if_exists: true

    # SolidCable redundant index (coincides with primary key)
    remove_index :solid_cable_messages, name: :index_solid_cable_messages_on_id, if_exists: true
  end
end
