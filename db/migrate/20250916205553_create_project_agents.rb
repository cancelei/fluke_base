class CreateProjectAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :project_agents do |t|
      t.references :project, null: false, foreign_key: true
      t.string :provider
      t.string :model

      t.timestamps
    end
  end
end
